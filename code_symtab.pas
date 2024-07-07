{   Routines to manipulate symbol tables.
*
*   Symbol tables are tree structured.  Symbols in a symbol table may have
*   a subordinate scope for new symbols.  For example, subroutines have their
*   own scope for local symbols.  The subroutine name symbol therefore is also
*   the name of the subordinate scope.  This subordinate symbol table points
*   back to the subroutine name symbol.
*
*   The root symbol table is at CODE.SYM_ROOT.  The current symbol table for new
*   local symbols is pointed to by CODE.SCOPE_P.
}
module code_symtab;
define code_symtab_init;
define code_symtab_new;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_SYMTAB_INIT (CODE, MEM, SYMTAB)
*
*   Initialize the symbol table SYMTAB.  The table will be initialized to not
*   have a parent symbol.  MEM is the parent memory context to use.  A
*   subordinate memory context will be created for the symbol table.
}
procedure code_symtab_init (           {initialize symbol table descriptor}
  in out  code: code_t;                {CODE library use state}
  in out  mem: util_mem_context_t;     {parent mem context, will create subordinate}
  out     symtab: code_symtab_t);      {symbol table to initialize}
  val_param;

begin
  util_mem_context_get (mem, symtab.mem_p); {create subordinate memory context}
  util_mem_context_err_bomb (symtab.mem_p); {bomb on didn't get memory}

  symtab.parent_p := nil;              {init to no parent symbol}

  string_hash_create (                 {create hash table to store symbols in}
    symtab.hash,                       {returned handle to hash table}
    code.config.n_symbuck,             {number of hash table buckets}
    code.config.symlen_max,            {max supported symbol name length}
    sizeof(code_symbol_t),             {size of data for each table entry}
    [string_hashcre_nodel_k],          {will not deallocate individual entries}
    symtab.mem_p^);                    {parent memory context to use}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYMTAB_NEW (CODE, PARSYM, SYMTAB_P)
*
*   Create and initialize a new symbol table structure.  PARSYM is the symbol
*   the new symbol table will be a sub-scope of.  SYMTAB_P is returned pointing
*   to the new symbol table structure.
}
procedure code_symtab_new (            {create new subordinate symbol table}
  in out  code: code_t;                {CODE library use state}
  in out  parsym: code_symbol_t;       {parent symbol new table subordinate to}
  out     symtab_p: code_symtab_p_t);  {pointer to new symbol table}
  val_param;

begin
  util_mem_grab (                      {alloc mem for new symbol table descriptor}
    sizeof(symtab_p^), parsym.symtab_p^.mem_p^, false, symtab_p);
  util_mem_grab_err_bomb (symtab_p, sizeof(symtab_p^)); {bomb on didn't get memory}

  code_symtab_init (                   {do basic initialization of new structure}
    code, parsym.symtab_p^.mem_p^, symtab_p^);

  symtab_p^.parent_p := addr(parsym);  {link back to parent scope symbol}
  end;
