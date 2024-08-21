{   Handling hierarchical symbol scopes.
}
module code_scope;
define code_scope_push;
define code_scope_pop;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Local subroutine CODE_SCOPE_INIT (CODE, SCOPE)
*
*   Initialize the SCOPE data structure to default or benign value.  The parent
*   scope is initialized to the current scope.
}
procedure code_scope_init (            {init scope data structure}
  in out  code: code_t;                {CODE library use state}
  in out  scope: code_scope_t);        {data structure to initialize}
  val_param; internal;

begin
  scope.parscope_p := code.scope_p;    {link back to parent scope}
  scope.symbol_p := nil;               {init to not private to a symbol}
  scope.symtab_scope_p := nil;         {init all symbol tables to not created}
  scope.symtab_vcon_p := nil;
  scope.symtab_dtype_p := nil;
  scope.symtab_rout_p := nil;
  scope.symtab_label_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine CODE_SCOPE_PUSH (CODE)
*
*   Create a new scope and set it as the current scope.  The scope is
*   initialized as a child of the current scope.
}
procedure code_scope_push (            {create new subordinate scope, make curr}
  in out  code: code_t);               {CODE library use state}
  val_param;

var
  scope_p: code_scope_p_t;             {to new scope}

begin
  code_alloc_global (code, sizeof(scope_p^), scope_p); {create new scope descriptor}
  code_scope_init (code, scope_p^);    {init the new descriptor}
  code.scope_p := scope_p;             {make the new scope current}
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
  if code.scope_p^.parscope_p = nil then return; {no parent scope to pop to ?}

  code.scope_p := code.scope_p^.parscope_p; {switch to parent scope}
  end;
