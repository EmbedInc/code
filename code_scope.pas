{   Handling hierarchical symbol scopes.
}
module code_scope;
define code_scope_init;
define code_scope_push;
define code_scope_pop;
define code_scope_show;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_SCOPE_INIT (SCOPE)
*
*   Initialize the scope descriptor to default or benign values.
}
procedure code_scope_init (            {init a scope descriptor}
  out     scope: code_scope_t);        {descriptor to initialize}
  val_param;

begin
  scope.parscope_p := nil;             {no parent scope}
  scope.symbol_p := nil;               {no symbol defining this scope}
  scope.symtab_scope_p := nil;         {init all symbol tables to not created}
  scope.symtab_vcon_p := nil;
  scope.symtab_dtype_p := nil;
  scope.symtab_label_p := nil;
  scope.symtab_other_p := nil;
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
  in out  code: code_t;                {CODE library use state}
  in out  sym: code_symbol_t);         {symbol defining the new scope}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  scope_p: code_scope_p_t;             {to new scope}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  if sym.subscope_p <> nil then begin  {symbol already has a subordinate scope ?}
    sys_msg_parm_vstr (msg_parm[1], sym.name_p^);
    code_err_atline (code, 'code', 'err_symtab_subscope', msg_parm, 1);
    end;
  if sym.subtab_p <> nil then begin    {symbol already has a subordinate sym table ?}
    sys_msg_parm_vstr (msg_parm[1], sym.name_p^);
    code_err_atline (code, 'code', 'err_symtab_subtab', msg_parm, 1);
    end;

  code_alloc_global (code, sizeof(scope_p^), scope_p); {create new scope descriptor}
  code_scope_init (scope_p^);          {init the new scope descriptor}
  scope_p^.parscope_p := code.scope_p; {link back to parent scope}
  scope_p^.symbol_p := addr(sym);      {link to symbol defining this scope}

  sym.subscope_p := scope_p;           {this symbol now defines a scope}
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
{
********************************************************************************
*
*   Subroutine CODE_SCOPE_SHOW (CODE, SCOPE, LEV)
*
*   Show the symbols in the scope SCOPE, and the tree of subordinate scopes.
*   LEV is the nesting level to show the symbols directly in SCOPE at.
}
procedure code_scope_show (            {show scope tree}
  in out  code: code_t;                {CODE library use state}
  in      scope: code_scope_t;         {the scope to show}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param;

begin
  if scope.symtab_scope_p <> nil then begin
    code_symtab_show (code, scope.symtab_scope_p^, lev);
    end;

  if scope.symtab_vcon_p <> nil then begin
    code_symtab_show (code, scope.symtab_vcon_p^, lev);
    end;

  if scope.symtab_dtype_p <> nil then begin
    code_symtab_show (code, scope.symtab_dtype_p^, lev);
    end;

  if scope.symtab_label_p <> nil then begin
    code_symtab_show (code, scope.symtab_label_p^, lev);
    end;

  if scope.symtab_other_p <> nil then begin
    code_symtab_show (code, scope.symtab_other_p^, lev);
    end;
  end;
