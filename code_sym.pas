{   Symbol manipulation
}
module code_sym;
define code_sym_new;
define code_sym_lookup;
define code_sym_new_currscope;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_SYM_NEW (CODE, NAME, TABLE, SYM_P, STAT)
*
*   Create a new symbol.  The symbol will be named NAME and added to the symbol
*   table TABLE.  SYM_P is returned pointing to the new symbol descriptor.  The
*   new symbol will be initialized to undefined type.
*
*   It is an error if the symbol already exists in the symbol table.
}
procedure code_sym_new (               {create new symbol, err if exists}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to create}
  in out  table: code_symtab_t;        {symbol table to add the symbol to}
  out     sym_p: code_symbol_p_t;      {returned pointer to new symbol}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  pos: string_hash_pos_t;              {position within symbol table}
  found: boolean;                      {symbol found in symbol table}
  name_p: string_var_p_t;              {pointer to name in symbol table}

begin
  string_hash_pos_lookup (             {get position for requested name}
    table.hash, name, pos, found);
  if found then begin                  {symbol of this name already exists ?}
    code_errset_sym_exist (pos, stat); {set symbol already exists error status}
    sym_p := nil;                      {indicate not returning with new symbol}
    return;                            {return with error}
    end;

  string_hash_ent_add (                {add the symbol to the hash table}
    pos,                               {hash table position to add at}
    name_p,                            {returned pointer to name string in table}
    sym_p);                            {returned pointer to symbol data in table}

  sym_p^.name_p := name_p;             {save pointer to symbol name string}
  fline_cpos_init (sym_p^.pos);        {init to no source code position}
  sym_p^.comm_p := nil;                {init to no comments apply}
  sym_p^.symtab_p := addr(table);      {save pointer to symbol table sym is in}
  sym_p^.flags := [];                  {init to no modifier flags}
  sym_p^.app_p := nil;                 {init pointer private to app}
  sym_p^.symtype := code_symtype_undef_k; {init symbol to undefined}

  sys_error_none (stat);
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYM_LOOKUP (CODE, NAME, SYMTAB, SYM_P)
*
*   Look up the symbol NAME in the symbol SYMTAB.  SYM_P is returned pointing to
*   the symbol if found, and NIL if not found.
}
procedure code_sym_lookup (            {look up symbol name in a symbol table}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to look up}
  in      symtab: code_symtab_t;       {symbol table to look up name in}
  out     sym_p: code_symbol_p_t);     {returned pointer to symbol, NIL if not found}
  val_param;

var
  name_p: string_var_p_t;              {pointer to name string in symbol table}

begin
  string_hash_ent_lookup (             {look up name in hash table}
    symtab.hash,                       {hash table to look in}
    name,                              {entry name to look for}
    name_p,                            {returned pointer to name in hash table}
    sym_p);                            {returned pointer to data for this entry}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYM_NEW_CURRSCOPE (CODE, NAME, SYM_P, STAT)
*
*   Create a new symbol within the current symbol scope.  NAME is the name of
*   the symbol to create.  SYM_P is returned pointing to the new symbol.  The
*   symbol type will be initialized to undefined.
}
procedure code_sym_new_currscope (     {create new symbol in curr scope, err if exists}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to create}
  out     sym_p: code_symbol_p_t;      {returned pointer to new symbol}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  code_sym_new (                       {create new symbol}
    code,                              {CODE library use state}
    name,                              {name of symbol to create}
    code.scope_p^,                     {symbol table to create new symbol in}
    sym_p,                             {returned pointer to the new symbol}
    stat);                             {completion status}
  end;
