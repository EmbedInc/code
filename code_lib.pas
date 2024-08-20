{   High level library management.
}
module code_lib;
define code_lib_def;
define code_lib_new;
define code_lib_end;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_LIB_DEF (CFG)
*
*   Set the configuration parameters for creating a new use of this library to
*   default values.
*
*   This routine should always be called before specific configuration
*   parameters are set by the application.  This allows new configuration
*   parameters to be transparently added, and allows the application to not be
*   aware of all possible configuration parameters.
*
*   The source code of this routine is the one place the defaults are
*   hard-coded.
}
procedure code_lib_def (               {set library creation parameters to default}
  out     cfg: code_inicfg_t);         {parameters for creating a library use}
  val_param;

begin
  cfg.mem_p := addr(util_top_mem_context); {parent memory context}
  cfg.symlen_max := 32;                {max supported length of symbol names}
  cfg.n_symbuck := 128;                {number of hash buckets in symbol tables}
  end;
{
********************************************************************************
*
*   Subroutine CODE_LIB_NEW (INICFG, CODE_P, STAT)
*
*   Start a new use of the CODE library.  CODE_P is returned pointing to the new
*   libaray use state.  INICFG contains configuration parameters for the new use
*   state.  The state of INICFG is irrelevant to the libarary use state after
*   this call.  INICFG is only used for initial configuration choices.
*
*   On error, CODE_P is returned NIL, and STAT indicates the error.  Otherwise
*   STAT is returned indicating no error.
}
procedure code_lib_new (               {create new use of the CODE library}
  in      inicfg: code_inicfg_t;       {configuration parameters}
  out     code_p: code_p_t;            {returned pointer to new library use state}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  mem_p: util_mem_context_p_t;         {pointer to new private memory context}
  sym_p: code_symbol_p_t;              {scratch pointer to symbol data}

label
  abort1;

begin
{
*   Create the basic descriptor and its private memory context.
}
  code_p := nil;                       {init to new use not created}

  util_mem_context_get (inicfg.mem_p^, mem_p); {create mem context for the new use}
  if util_mem_context_err (mem_p, stat) {error getting the mem context ?}
    then return;

  util_mem_grab (                      {allocate descriptor for new lib use}
    sizeof(code_p^),                   {amount of memory to allocate}
    mem_p^,                            {memory context to allocate under}
    false,                             {will not individually deallocate this}
    code_p);                           {returned pointer to the new memory}
  if util_mem_grab_err (code_p, sizeof(code_p^), stat) {error getting the memory ?}
    then goto abort1;

  code_p^.mem_p := mem_p;              {save pointer to mem context for this lib use}
{
*   Fill in remaining fields.
}
  code_p^.config.symlen_max := inicfg.symlen_max;
  code_p^.config.n_symbuck := inicfg.n_symbuck;
  fline_cpos_init (code_p^.parse.pos);
  code_p^.parse.level := 0;
  code_p^.parse.nextlevel := 0;
  code_p^.comm_block_p := nil;
  code_p^.comm_eol_p := nil;
  code_symtab_init (                   {initialize root symbol table}
    code_p^, code_p^.mem_p^, code_p^.sym_root);
  code_p^.scope_p := addr(code_p^.sym_root); {init to at root scope}
{
*   Create the top level scope MEM, and then create the memories symbol table
*   subordinate to it.
}
  code_sym_new_currscope (             {create top level MEM symbol}
    code_p^,                           {CODE library use state}
    string_v('MEM'),                   {symbol name}
    sym_p,                             {returned pointer to the new symbol}
    stat);
  if sys_error(stat) then goto abort1;
  sym_p^.symtype := code_symtype_scope_k; {this symbol is a subordinate scope}

  code_symtab_new (                    {create memories symbol table}
    code_p^, sym_p^, code_p^.memsym_p);
  return;                              {normal return, new lib use created}
{
*   Error exits.  STAT is already set.
}
abort1:
  util_mem_context_del (mem_p);        {delete the new memory context}
  end;
{
********************************************************************************
*
*   Subroutine CODE_LIB_END (CODE_P)
*
*   End a use of the CODE library.  CODE_P must point to the CODE library use
*   state on entry.  It will be returned NIL.
}
procedure code_lib_end (               {end a use of the CODE library}
  in out  code_p: code_p_t);           {pointer to lib use state, returned NIL}
  val_param;

var
  mem_p: util_mem_context_p_t;         {pointer to mem context for the lib use}

begin
  if code_p = nil then return;         {ignore request if no library use state}

  mem_p := code_p^.mem_p;              {make local copy of pointer to mem context}
  util_mem_context_del (mem_p);        {deallocate all dyn mem, delete context}

  code_p := nil;                       {return lib use state pointer invalid}
  end;
