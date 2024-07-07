{   Handling hierarchical symbol scopes.
}
module code_scope;
define code_scope_new;
define code_scope_pop;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_SCOPE_NEW (CODE, PARSYM)
*
*   Create a new symbol scope and set it as the current scope.  The new scope
*   will be subordinate to the parent symbol PARSYM.
}
procedure code_scope_new (             {create new symbol scope, make it current}
  in out  code: code_t;                {CODE library use state}
  in out  parsym: code_symbol_t);      {parent symbol new scope will be under}
  val_param;

begin
  code_symtab_new (                    {create symbol table for the new scope}
    code,                              {CODE library use state}
    parsym,                            {parent symbol new scope is subordinate to}
    code.scope_p);                     {returned pointer to the new symbol table}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SCOPE_POP (CODE)
*
*   Pop back to the parent scope of the current, and make it the current.
}
procedure code_scope_pop (             {pop back to parent scope}
  in out  code: code_t);               {CODE library use state}
  val_param;

begin
  if code.scope_p = nil then return;   {no current scope ?}
  if code.scope_p^.parent_p = nil then return; {no current parent symbol ?}
  if code.scope_p^.parent_p^.symtab_p = nil then return; {no parent symbol table ?}

  code.scope_p := code.scope_p^.parent_p^.symtab_p; {switch to parent scope}
  end;
