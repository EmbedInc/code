{   Memory allocation.
}
module code_alloc;
define code_alloc_global;
define code_alloc_symtab;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_ALLOC_GLOBAL (CODE, SIZE, NEW_P)
*
*   Allocate memory under the CODE library's root private memory context.  The
*   new memory can not be deallocated later.  It is only deallocated when the
*   memory context is deleted.  No additional memory is used per allocated
*   block.
*
*   SIZE is the requested size of the new memory, and NEW_P is returned pointing
*   to the start address of the newly allocated region.
}
procedure code_alloc_global (          {alloc mem under CODE context, can't individually dealloc}
  in out  code: code_t;                {CODE library use state}
  in      size: sys_int_adr_t;         {amount of memory to allocate, bytes}
  out     new_p: univ_ptr);            {returned pointer to the new memory}
  val_param;

begin
  util_mem_grab (                      {allocate the new memory}
    size,                              {amount of memory required}
    code.mem_p^,                       {context to allocate the memory under}
    false,                             {will not need to individually deallocate}
    new_p);                            {returned pointer to the new memory}
  util_mem_grab_err_bomb (new_p, size); {bomb program if didn't get new memory}
  end;
{
********************************************************************************
*
*   Subroutine CODE_ALLOC_SYMTAB (SYMTAB, SIZE, NEW_P)
*
*   Allocate memory from the context of the symbol table SYMTAB.  SIZE is the
*   requested size of the new memory, and NEW_P is returned pointing to the
*   start of the new memory.  The memory can not be individually deallocated
*   later.  It is automatically deallocated when the symbol table is
*   deallocated.
*
*   The program will be bombed with an appropriate error message when the memory
*   can not be allocated.
}
procedure code_alloc_symtab (          {alloc perm mem from symbol table context}
  in out  symtab: code_symtab_t;       {context to allocate memory from}
  in      size: sys_int_adr_t;         {amount of memory to allocate, bytes}
  out     new_p: univ_ptr);            {returned pointer to the new memory}
  val_param;

begin
  string_hash_mem_alloc_ndel (symtab.hash, size, new_p); {try get the memory}
  util_mem_grab_err_bomb (new_p, size); {bomb program if didn't get new memory}
  end;
