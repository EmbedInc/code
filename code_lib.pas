{   High level library management.
}
module code_lib;
define code_lib_new;
define code_lib_end;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_LIB_NEW (MEM, CODE_P, STAT)
*
*   Start a new use of the CODE library.  MEM is the parent memory context.  A
*   subordinate context will be created for the exclusive use of the new CODE
*   library use.
*
*   On no error, CODE_P is returned pointing to the new library use state, and
*   STAT is set to no error.
*
*   On error, CODE_P is returned NIL, and STAT indicates the error.
}
procedure code_lib_new (               {create new use of the CODE library}
  in out  mem: util_mem_context_t;     {parent mem context, will create subordinate}
  out     code_p: code_p_t;            {returned pointer to new library use state}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  mem_p: util_mem_context_p_t;         {pointer to new private memory context}

begin
  code_p := nil;                       {init to new use not created}

  util_mem_context_get (mem, mem_p);   {create mem context for the new use}
  if util_mem_context_err (mem_p, stat) {error getting the mem context ?}
    then return;

  util_mem_grab (                      {allocate descriptor for new lib use}
    sizeof(code_p^),                   {amount of memory to allocate}
    mem_p^,                            {memory context to allocate under}
    false,                             {will not individually deallocate this}
    code_p);                           {returned pointer to the new memory}
  if util_mem_grab_err (code_p, sizeof(code_p^), stat) {error getting the memory ?}
    then return;

  code_p^.mem_p := mem_p;              {save pointer to mem context for this lib use}
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
