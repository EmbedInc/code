{   Interactive command processor.
}
module code_cmd;
define code_cmd;
%include 'code2.ins.pas';

const
  prompt_text = ': ';                  {prompt to user to enter new command}
  namewid = 8;                         {min chars cmd name width show in list}
{
********************************************************************************
*
*   Subroutine CODE_CMD (CODE, CONT, STAT)
*
*   Run an interactive command processor.  This allows the user to examine the
*   current CODE library state.
*
*   This command processor is intended to aid in debugging the CODE library and
*   applications that use it.  It is not intended as a feature for applications
*   to provide to end users during normal "production" operation.  As such,
*   documentation is short-hand and sparse.
*
*   CONT is returned indicating the user preference about how to continue the
*   application.  If an error is encountered, then CONT will indicate error and
*   STAT will be set to the specific error.
}
procedure code_cmd (                   {command processor to inspect data structures}
  in out  code: code_t;                {CODE library use state}
  out     cont: code_cmd_cont_t;       {user preferences about how to continue}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmds: string_var1024_t;              {command names, blank-separated, upper case}
  desc: string_list_t;                 {list of descriptions for each command}
  prompt: string_var4_t;               {prompt to have user enter next command}
  cmline: string_var8192_t;            {command line entered by user}
  p: string_index_t;                   {parse index into CMLINE}
  cmd: string_var32_t;                 {command name from command line, upper case}
  parm: string_var8192_t;              {parameter parsed from command line}
  xtra: string_var32_t;                {extra parameter after end of command}
  pick: sys_int_machine_t;             {number of keyword picked from list}
  scope_curr_p: code_scope_p_t;        {to current scope}
  show: code_symshow_t;                {control state for showing symbols}
  i1: sys_int_machine_t;               {integer command parameter}
  sym_p: code_symbol_p_t;              {scratch symbol pointer}
  sytypes: code_symtype_t;             {scratch set of symbol types}

label
  loop_command, show_scope, done_command,
  parm_missing, parm_bad, parm_extra, error, remind, leave;
{
****************************************
*
*   Subroutine ADD_COMMAND (NAME, DSC)
*   This routine is local to CODE_CMD.
*
*   Add the command NAME to the end of the commands list.  DSC is a brief
*   description of the command.
}
procedure add_command (                {add command to commands list}
  in      name: string;                {name of command and parameters description}
  in      dsc: string);                {short command description}
  val_param; internal;

var
  vstr: string_var132_t;               {scratch var string}
  p: string_index_t;                   {CMDSTR parse index}
  tk: string_var132_t;                 {scratch token parsed from string}
  dstr: string_var132_t;               {assembled description string}
  stat: sys_err_t;                     {completion status}

begin
  vstr.max := size_char(vstr.str);     {init local var strings}
  tk.max := size_char(tk.str);
  dstr.max := size_char(dstr.str);
  dstr.len := 0;                       {init description string to empty}

  string_vstring (vstr, name, -1);     {make name and parameters var string}
  p := 1;                              {init CMDSTR parse index}
{
*   Extract the bare command name from cmd/parameters string.  Add the command
*   to the end of the list in CMDS, and initialize the description string with
*   the command name.
}
  string_token (vstr, p, dstr, stat);  {get bare command name into DSTR}
  sys_error_abort (stat, '', '', nil, 0);
  string_upcase (dstr);                {all command names stored upper case}
  if cmds.len > 0 then begin           {there is a previous command in list ?}
    string_append1 (cmds, ' ');        {add separator before new command}
    end;
  string_append (cmds, dstr);          {add this command to the end of the list}
{
*   Append any parameters in the cmd/parameters string to the description
*   string.
}
  while (p <= vstr.len) and then (vstr.str[p] = ' ') do begin {skip blanks}
    p := p + 1;
    end;
  if p <= vstr.len then begin          {command parameters string exists ?}
    string_substr (                    {extract command parameters string into TK}
      vstr,                            {string to extract from}
      p,                               {start index of substring}
      vstr.len,                        {end index of substring}
      tk);                             {extracted substring}
    string_append1 (dstr, ' ');        {blank separator before parameters}
    string_append (dstr, tk);          {add parameters to description string}
    end;
{
*   Append the string in DSC to the end of the description string.
}
  string_vstring (vstr, dsc, -1);      {make var string bare description}
  if vstr.len > 0 then begin           {there is a description to add ?}
    while dstr.len < namewid do begin  {pad command/parameters to common column}
      string_append1 (dstr, ' ');
      end;
    if dstr.str[dstr.len] <> ' ' then begin {make sure there is preceeding blank}
      string_append1 (dstr, ' ');
      end;
    string_appendn (dstr, '- ', 2);    {separator before text description}
    string_append (dstr, vstr);        {add description text}
    end;

  string_list_str_add (desc, dstr);    {add description to end of list}
  end;
{
****************************************
*
*   Function NOT_EOL
*   This function is local to CODE_CMD.
*
*   Return FALSE iff the command line in CMLINE has not been exhausted.
}
function not_eol:                      {check for unused command parameter}
  boolean;                             {found unused command parameter, in PARM}
  val_param; internal;

var
  stat: sys_err_t;                     {completion status}

begin
  string_token (cmline, p, xtra, stat);
  not_eol := not string_eos(stat);
  end;
{
****************************************
*
*   Subroutine SCOPENAME (SCOPE_P, NAME)
*   This routine is local to CODE_CMD.
*
*   Set NAME to the printable absolute name of the scope SCOPE.
}
procedure scopename (                  {make scope name string}
  in      scope_p: code_scope_p_t;     {to scope to make name of}
  in out  name: univ string_var_arg_t); {returned printable scope name}
  val_param; internal;

begin
  if scope_p = nil then begin          {no scope ?}
    string_vstring (name, 'No scope'(0), -1);
    return;
    end;

  if scope_p^.symbol_p = nil then begin {this scope has no symbol name ?}
    string_vstring (name, 'Root scope'(0), -1);
    return;
    end;

  code_symname_abs (code, scope_p^.symbol_p^, name); {make abs scope name}
  end;
{
****************************************
*
*   Start of main routine.
}
begin
  cmds.max := size_char(cmds.str);     {init local var strings}
  prompt.max := size_char(prompt.str);
  cmline.max := size_char(cmline.str);
  cmd.max := size_char(cmd.str);
  parm.max := size_char(parm.str);
  xtra.max := size_char(xtra.str);
{
*   Build the list of command names in CMDS.
}
  cmds.len := 0;                       {init the commands list to empty}
  string_list_init (desc, code.mem_p^); {create empty command descriptions list}
  desc.deallocable := false;           {don't need to deallocate entries separately}

  add_command ('?',                    {1}
    'Show list of commands');
  add_command ('Q',                    {2}
    'Quit the program');
  add_command ('GO',                   {3}
    'End command processing, continue program');
  add_command ('SL',                   {4}
    'List symbols in current scope');
  add_command ('ST [n]',               {5}
    'Show symbols up to N levels down');
  add_command ('SC [name]',            {6}
    'Show or set current scope, ".." parent');
  add_command ('SY [name]',            {7}
    'Show details of a symbol');
{
*   Initialize local state before command processing.
}
  cont.opt := code_cmd_cont_go_k;      {init to continue normally on exit}
  string_vstring (prompt, prompt_text, -1); {set PROMPT to the prompt string}
  scope_curr_p := addr(code.scope_root); {init current scope to root scope}
{
*   Get the next command from the user.
}
loop_command:
  string_prompt (prompt);              {prompt user to enter a new command}
  string_readin (cmline);              {get the command line into CMLINE}
  string_unpad (cmline);               {truncate trailing blanks}
  if cmline.len <= 0 then goto loop_command; {ignore blank input lines}

  p := 1;                              {init parse index into CMLINE}
  string_token (cmline, p, cmd, stat); {get command name}
  if sys_error_check (stat, '', '', nil, 0) then goto loop_command;
  string_upcase (cmd);                 {make upper case command name in CMD}
  string_tkpick (cmd, cmds, pick);     {pick this command from the list}
  case pick of                         {which command is it ?}
{
********************
*
*   ?
*
*   Show list of commands with short descriptions.
}
1: begin
  if not_eol then goto parm_extra;

  string_list_pos_abs (desc, 1);       {to first command description}
  while desc.str_p <> nil do begin     {loop thru the command descriptions}
    writeln (desc.str_p^.str:desc.str_p^.len); {show this description}
    string_list_pos_rel (desc, 1);     {to next description in list}
    end;                               {back to show next description string}
  end;
{
********************
*
*   Q
*
*   Quit the program.
}
2: begin
  if not_eol then goto parm_extra;
  cont.opt := code_cmd_cont_exit_k;    {indicate user wants to quit program}
  goto leave;
  end;
{
********************
*
*   GO
*
*   End command processing, continue the program.
}
3: begin
  if not_eol then goto parm_extra;
  cont.opt := code_cmd_cont_go_k;      {indicate user wants to continue the program}
  goto leave;
  end;
{
********************
*
*   SL
*
*   List the symbols in the current scope.
}
4: begin
  if not_eol then goto parm_extra;

  code_symshow_init (show);            {init symbol showing control state}
  show.maxlev := 1;                    {number of levels to show}
  code_scope_show (code, scope_curr_p^, 0, show); {show symbols in current scope}
  end;
{
********************
*
*   ST [n]
*
*   Show symbol tree from current scope up to N levels down.  Default is no
*   limit on the number of levels.
}
5: begin
  string_token_int (cmline, p, i1, stat); {try to get N}
  if string_eos(stat)
    then begin                         {no command parameter}
      i1 := 0;                         {indicate no levels limit}
      end
    else begin                         {got something}
      if sys_error(stat) then goto error;
      if not_eol then goto parm_extra;
      end
    ;

  scopename (scope_curr_p, parm);      {show current scope name}
  writeln (parm.str:parm.len);

  code_symshow_init (show);            {init symbol showing control state}
  show.maxlev := i1;                   {number of levels to show}
  code_scope_show (code, scope_curr_p^, 1, show); {show symbols in current scope}
  end;
{
********************
*
*   SC [name]
*
*   Show details about the current scope, or set to a new scope.  The special
*   scope name ".." pops up one level.
}
6: begin
  string_token (cmline, p, parm, stat); {try to get NAME}
  if string_eos(stat)
    then begin                         {no parameter}
      goto show_scope;                 {just show the current scope name}
      end
    else begin                         {got something}
      if sys_error(stat) then goto error;
      if not_eol then goto parm_extra;
      end
    ;
{
*   PARM is the name of the new scope to go to.
}
  if string_equal (parm, string_v('..'(0))) then begin {go up one level ?}
    if scope_curr_p^.parscope_p <> nil then begin {there is a parent scope ?}
      scope_curr_p := scope_curr_p^.parscope_p; {to the parent scope}
      end;
    goto show_scope;
    end;

  if scope_curr_p^.symtab_scope_p = nil then begin {no subordinates scopes ?}
    writeln ('There are no subordinate scopes.');
    goto done_command;
    end;

  code_sym_lookup (                    {look up name in subordinate scopes table}
    code, parm, scope_curr_p^.symtab_scope_p^, sym_p);
  if sym_p = nil then begin            {no such subordinate scope ?}
    writeln ('Subordinate scope "', parm.str:parm.len, '" does not exist.');
    goto done_command;
    end;
  if sym_p^.subscope_p = nil then begin {symbol isn't a scope ?}
    writeln ('Symbol "', parm.str:parm.len, '" is not a scope.');
    goto done_command;
    end;

  scope_curr_p := sym_p^.subscope_p;   {to scope of this symbol}

show_scope:
  scopename (scope_curr_p, parm);      {show current scope name}
  writeln (parm.str:parm.len);
  end;
{
********************
*
*   SY [name]
*
*   Show details of the symbol NAME.  When NAME is omitted the details of the
*   current scope symbol is shown.
}
7: begin
  string_token (cmline, p, parm, stat); {try to get NAME into PARM}
  if string_eos(stat)
    then begin                         {no parameter}
      parm.len := 0;
      end
    else begin                         {got something}
      if sys_error(stat) then goto error;
      if not_eol then goto parm_extra;
      end
    ;

  if parm.len <= 0
    then begin                         {show current scope symbol}
      sym_p := scope_curr_p^.symbol_p; {get pointer to scope symbol}
      if sym_p = nil then begin
        writeln ('Root scope does not have a symbol.');
        goto done_command;
        end;
      end
    else begin                         {PARM contains name of symbol to show}
      sytypes := [];                   {select all possible symbol types}
      sytypes := ~sytypes;
      code_sym_find (                  {find symbol in the current scope}
        code, parm, scope_curr_p^, sytypes, sym_p);
      if sym_p = nil then begin        {no such symbol in this scope ?}
        writeln ('No symbol "', parm.str:parm.len, '" in the current scope.');
        goto done_command;
        end;
      end
    ;
{
*   SYM_P is pointing to the symbol to show.
}
  code_symshow_init (show);            {init symbol showing control state}
  show.opt := show.opt + [
    code_symshow_commeol_k,            {show end of line comments}
    code_symshow_comm_k,               {show comment hierarchy}
    code_symshow_sub_k,                {show private subordinate symbols}
    code_symshow_source_k];            {show source code location}
  code_sym_show (code, sym_p^, 0, show); {show symbol info}
  end;
{
********************
*
*   Unrecognized command name.
}
otherwise
    writeln ('Command "', cmd.str:cmd.len, '" is not recognized.');
    goto remind;
    end;                               {end of which command cases}
done_command:                          {done with the current command}
  goto loop_command;                   {done with this command, back for next}

parm_missing:                          {missing required parameter}
  writeln ('A required parameter to command ', cmd.str:cmd.len, ' is missing.');
  goto remind;

parm_bad:                              {parameter in PARM is bad}
  writeln ('Command parameter "', parm.str:parm.len, '" makes no sense here.');
  goto remind;

parm_extra:                            {extra parameter, in PARM}
  writeln ('Extra parameter "', xtra.str:xtra.len, '" does not belong here.');
  goto remind;

error:                                 {error while processig command}
  writeln ('Error in command "', cmd.str:cmd.len, '".');
  sys_error_print (stat, '', '', nil, 0);
  goto remind;

remind:                                {show reminder how to get commands list}
  writeln ('Enter "?" for list of commands.');
  goto loop_command;

leave:                                 {common exit point, STAT set}
  string_list_kill (desc);             {deallocate command descriptions list}
  if sys_error(stat) then begin        {returning with error ?}
    cont.opt := code_cmd_cont_err_k;   {set continuation to error condition}
    end;
  end;
