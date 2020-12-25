{   Public include file for the CODE library.  This library maintains in-memory
*   descriptions of executable code.  These descriptions are independent of any
*   particular computer language.
}
const
  code_subsys_k = -72;                 {Embed subsystem ID for the CODE library}

type
  code_p_t = ^code_t;
  code_t = record                      {state for one use of this library}
    mem_p: util_mem_context_p_t;       {context for all dyn mem of this CODE lib use}
    end;
{
*   Functions and subroutines.
}
procedure code_end (                   {end a use of the CODE library}
  in out  code_p: code_p_t);           {pointer to lib use state, returned NIL}
  val_param; extern;

procedure code_new (                   {create new use of the CODE library}
  in out  mem: util_mem_context_t;     {parent mem context, will create subordinate}
  out     code_p: code_p_t;            {returned pointer to new library use state}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
