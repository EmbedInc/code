{   Routines to manipulate symbol tables.
}
module code_symtab;
define code_symtab_exist_scope;
define code_symtab_new_sym;
define code_symtab_symtype;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Internal subroutine SYMTAB_CREATE (CODE, SYMTAB, MEM)
*
*   Create the actual symbols hash table within the symbol table descriptor
*   SYMTAB.  MEM is the memory context to allocate the new symbols hash table
*   within.
}
procedure symtab_create (              {create symbol names hash table}
  in out  code: code_t;                {CODE library use state}
  in out  symtab: code_symtab_t;       {symbol table to create hash table within}
  in out  mem: util_mem_context_t);    {parent memory context}
  val_param; internal;

begin
  string_hash_create (                 {create hash table to store symbols in}
    symtab.hash,                       {returned handle to hash table}
    code.config.n_symbuck,             {number of hash table buckets}
    code.config.symlen_max,            {max supported symbol name length}
    sizeof(code_symbol_t),             {size of data for each table entry}
    [string_hashcre_nodel_k],          {will not deallocate individual entries}
    mem);                              {parent memory context to use}
  end;
{
********************************************************************************
*
*   Function CODE_SYMTAB_EXIST_SCOPE (CODE, SCOPE, SYMTAB_P)
*
*   Make sure a symbol table within a scope exists.  Nothing is done if the
*   symbol table already exists.  SYMTAB_P is the pointer to the symbol table
*   within the scope SCOPE.  A new symbol table will be created if SYMTAB_P is
*   originally NIL.  SYMTAB_P is always non-NIL on return.
*
*   The function value is the pointer to the symbol table, the same value that
*   is returned in SYMTAB_P.
}
function code_symtab_exist_scope (     {make sure symbol table in scope exists}
  in out  code: code_t;                {CODE library use state}
  in out  scope: code_scope_t;         {scope symbol table will be within}
  in out  symtab_p: code_symtab_p_t)   {to table, will not be NIL}
  :code_symtab_p_t;                    {pointer to the symbol table}
  val_param;

begin
  if symtab_p = nil then begin         {doesn't already exist, create ?}
    code_alloc_global (code, sizeof(symtab_p^), symtab_p); {alloc sym table mem}
    util_mem_grab_err_bomb (symtab_p, sizeof(symtab_p^));
    symtab_p^.scope_p := addr(scope);  {point to scope this symbol table within}
    symtab_p^.parsym_p := nil;         {not a sub-symbol table}
    symtab_create (code, symtab_p^, code.mem_p^); {create the symbol names hash table}
    end;

  code_symtab_exist_scope := symtab_p; {return pointer to the symbol table}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYMTAB_NEW_SYM (CODE, SYM, SYMTAB_P)
*
*   Create a new symbol table, which will be subordinate to the symbol SYM.
*   SYMTAB_P is returned pointing to the new symbol table.
}
procedure code_symtab_new_sym (        {create symbol table subordinate to a symbol}
  in out  code: code_t;                {CODE library use state}
  in out  sym: code_symbol_t;          {parent symbol for the new symbol table}
  out     symtab_p: code_symtab_p_t);  {to the new symbol table}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  mem_p: util_mem_context_p_t;         {to mem context symbol is allocated in}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  if sym.subtab_p <> nil then begin    {symbol already has a subordinate sym table ?}
    sys_msg_parm_vstr (msg_parm[1], sym.name_p^);
    code_err_atline (code, 'code', 'err_symtab_subtab', msg_parm, 1);
    end;
  if sym.subscope_p <> nil then begin  {symbol already has a subordinate scope ?}
    sys_msg_parm_vstr (msg_parm[1], sym.name_p^);
    code_err_atline (code, 'code', 'err_symtab_subscope', msg_parm, 1);
    end;

  code_alloc_symtab (                  {allocate mem for new sym table descriptor}
    sym.symtab_p^,                     {parent sym table to alloc memory under}
    sizeof(symtab_p^),                 {amount of memory to allocate}
    symtab_p);                         {returned pointer to the new memory}

  symtab_p^.scope_p := nil;            {new table not at scope level}
  symtab_p^.parsym_p := addr(sym);     {set pointer to parent symbol}
  mem_p := code_sym_mem(sym);          {get symbol's memory context}
  symtab_create (code, symtab_p^, mem_p^); {create symbol names hash table}

  sym.subtab_p := symtab_p;            {this symbol now has subordinate sym table}
  end;
{
********************************************************************************
*
*   Function CODE_SYMTAB_SYMTYPE (CODE, SCOPE, SYMTYPE)
*
*   Get the pointer to the symbol table within scope SCOPE for the symbol type
*   SYMTYPE.  The symbol table is created if it did not previously exist.
}
function code_symtab_symtype (         {get symbol table for particular symbol type}
  in out  code: code_t;                {CODE library use state}
  in out  scope: code_scope_t;         {scope the symbol is within}
  in      symtype: code_symtype_k_t)   {type of symbol}
  :code_symtab_p_t;                    {pointer to the symbol table, will exist}
  val_param;

var
  tab_pp: ^code_symtab_p_t;            {pointer to symbol table pointer in scope}

begin
  case symtype of                      {which type of symbol is it ?}
code_symtype_scope_k: tab_pp := addr(scope.symtab_scope_p);
code_symtype_const_k: tab_pp := addr(scope.symtab_vcon_p);
code_symtype_dtype_k: tab_pp := addr(scope.symtab_dtype_p);
code_symtype_var_k: tab_pp := addr(scope.symtab_vcon_p);
code_symtype_proc_k: tab_pp := addr(scope.symtab_scope_p);
code_symtype_prog_k: tab_pp := addr(scope.symtab_scope_p);
code_symtype_module_k: tab_pp := addr(scope.symtab_scope_p);
code_symtype_label_k: tab_pp := addr(scope.symtab_label_p);
otherwise
  tab_pp := addr(scope.symtab_other_p);
  end;

  code_symtab_symtype :=               {return pointer to selected symbol table}
    code_symtab_exist_scope (code, scope, tab_pp^);
  end;
