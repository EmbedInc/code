module code_sym_find;
define code_sym_find;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Local subroutine LOOKIN_TABLE (CODE, NAME, TABLE_P, TYTABLE, TYALLOWED, SYM_P)
*
*   Look for the symbol in the symbol table pointed to by TABLE_P.  TYTABLE is
*   the set of symbol types that can be in the table, and TYALLOWED is the set
*   of symbol types allowed by the caller.  When TYALLOWED is the empty set,
*   then all symbol types are allowed.
*
*   SYM_P is returned pointing to the matching symbol, or NIL when no matching
*   symbol is found or was possible.
}
procedure lookin_table (               {look for symbol in specific symbol table}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {NAME of symbol to look for}
  in      table_p: code_symtab_p_t;    {to symbol table to look in, may be NIL}
  in      tytable: code_symtype_t;     {set of symbol types that could be in table}
  in      tyallowed: code_symtype_t;   {set of allowed symbol types}
  out     sym_p: code_symbol_p_t);     {to symbol when found, NIL when not found}
  val_param; internal;

begin
  sym_p := nil;                        {init to matching symbol not found}

  if table_p = nil then return;        {symbol table doesn't exist ?}

  if                                   {symbol can't be in this table ?}
      (tyallowed <> []) and            {specific allowed set of symbols specified ?}
      ((tyallowed * tytable) = [])     {no allowed symbol types in this table ?}
      then begin
    return;                            {symbol can't be here, don't bother look}
    end;

  code_sym_lookup (                    {look for the symbol in the symbol table}
    code,                              {CODE library use state}
    name,                              {symbol name}
    table_p^,                          {symbol table to look in}
    sym_p);                            {returned pointer to symbol, if found}
  if sym_p = nil then return;          {no symbol of that name ?}

  if                                   {symbol is not one of the allowed types ?}
      (tyallowed <> []) and            {only specific symbol types allowed}
      (not (sym_p^.symtype in tyallowed)) {symbol not one of the allowed types ?}
      then begin
    sym_p := nil;                      {indicate no matching symbol in this table}
    end;
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYM_FIND (CODE, NAME, SCOPE, SYTYPES, SYM_P)
*
*   Find a symbol within the scope SCOPE.  NAME is the name of the symbol.
*
*   SYTYPES is the set of allowable symbol types.  The special case of the empty
*   set allows all symbol types.
*
*   SYM_P is returned pointing to the symbol descriptor.  If no symbol meeting
*   all the criteria is found, then SYM_P is returned NIL.
*
*   When multiple symbol types are allowed, then symbols are looked for in the
*   precedence order:
*
*     Variables or constants.
*     Symbols that have their own scopes, like subroutines.
*     Data types.
*     Labels.
*     All other symbols.
}
procedure code_sym_find (              {find matching symbol in specific scope}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to find}
  in      scope: code_scope_t;         {scope to look for the symbol in}
  in      sytypes: code_symtype_t;     {allowable symbol types}
  out     sym_p: code_symbol_p_t);     {to found symbol, NIL = not found}
  val_param;

begin
  lookin_table (                       {look for variables and constants}
    code,
    name,
    scope.symtab_vcon_p,
    [ code_symtype_const_k,
      code_symtype_var_k],
    sytypes,
    sym_p);
  if sym_p <> nil then return;

  lookin_table (                       {look for symbols that have scopes}
    code,
    name,
    scope.symtab_scope_p,
    [ code_symtype_scope_k,
      code_symtype_proc_k,
      code_symtype_prog_k,
      code_symtype_module_k],
    sytypes,
    sym_p);
  if sym_p <> nil then return;

  lookin_table (                       {look for data types}
    code,
    name,
    scope.symtab_dtype_p,
    [ code_symtype_dtype_k],
    sytypes,
    sym_p);
  if sym_p <> nil then return;

  lookin_table (                       {look for labels}
    code,
    name,
    scope.symtab_label_p,
    [ code_symtype_label_k],
    sytypes,
    sym_p);
  if sym_p <> nil then return;

  lookin_table (                       {look for all other symbol types}
    code,
    name,
    scope.symtab_other_p,
    [ code_symtype_invalid_k,
      code_symtype_unk_k,
      code_symtype_undef_k,
      code_symtype_memory_k,
      code_symtype_memreg_k,
      code_symtype_adrsp_k,
      code_symtype_adrreg_k,
      code_symtype_enum_k,
      code_symtype_field_k,
      code_symtype_alias_k,
      code_symtype_com_k],
    sytypes,
    sym_p);
  end;
