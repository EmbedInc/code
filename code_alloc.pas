{   Memory allocation.
}
module code_alloc;
define code_alloc_perm;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_ALLOC_PERM (CODE, SIZE, NEW_P)
*
*   Allocate memory under the CODE library's private memory context.  The new
*   memory can not be deallocated later.  It is only deallocated when the memory
*   context is deleted.  No additional memory is used per allocated block.
*
*   SIZE is the requested size of the new memory, and NEW_P is returned pointing
*   to the start address of the newly allocated region.
}
procedure code_alloc_perm (            {alloc mem under CODE context, can't individually dealloc}
  in out  code: code_t;                {CODE library use state}
  in      size: sys_int_adr_t;         {amount of memory to allocate, bytes}
  out     new_p: univ_ptr);            {returned pointer to the new memory}
  val_param;

var
  stat: sys_err_t;                     {error status}

begin
  util_mem_grab (                      {allocate the new memory}
    size,                              {amount of memory required}
    code.mem_p^,                       {context to allocate the memory under}
    false,                             {will not need to individually deallocate}
    new_p);                            {returned pointer to the new memory}

  if new_p <> nil then return;         {got the memory ?}
  discard( util_mem_grab_err (new_p, size, stat) ); {set STAT to indicate the error}
  sys_error_print (stat, '', '', nil, 0); {write error message}
  sys_bomb;                            {abort program with error status}
  end;
