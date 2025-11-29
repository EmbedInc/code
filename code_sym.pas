{   Symbol manipulation.
}
module code_sym;
define code_sym_mem;
define code_sym_new;
define code_sym_lookup;
define code_sym_inscope;
define code_sym_curr;
define code_sym_show;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Function CODE_SYM_MEM (SYM)
*
*   Get the pointer to the memory context the symbol SYM was allocated in.
}
function code_sym_mem (                {get memory context symbol is allocated in}
  in      sym: code_symbol_t)          {symbol to get memory context of}
  :util_mem_context_p_t;               {retrurned pointer to symbol's mem context}
  val_param;

begin
  code_sym_mem := string_hash_mem (sym.symtab_p^.hash);
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYM_NEW (CODE, NAME, TABLE, SYM_P, STAT)
*
*   Create a new symbol.  The symbol will be named NAME and added to the symbol
*   table TABLE.  SYM_P is returned pointing to the new symbol descriptor.  The
*   new symbol will be initialized to undefined type.
*
*   It is an error if the symbol already exists in the symbol table.
}
procedure code_sym_new (               {create new symbol, err if exists}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to create}
  in out  table: code_symtab_t;        {symbol table to add the symbol to}
  out     sym_p: code_symbol_p_t;      {returned pointer to new symbol}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  pos: string_hash_pos_t;              {position within symbol table}
  found: boolean;                      {symbol found in symbol table}
  name_p: string_var_p_t;              {pointer to name in symbol table}

begin
  string_hash_pos_lookup (             {get position for requested name}
    table.hash, name, pos, found);
  if found then begin                  {symbol of this name already exists ?}
    code_errset_sym_exist (pos, stat); {set symbol already exists error status}
    sym_p := nil;                      {indicate not returning with new symbol}
    return;                            {return with error}
    end;

  string_hash_ent_add (                {add the symbol to the hash table}
    pos,                               {hash table position to add at}
    name_p,                            {returned pointer to name string in table}
    sym_p);                            {returned pointer to symbol data in table}

  sym_p^.name_p := name_p;             {save pointer to symbol name string}
  fline_cpos_init (sym_p^.pos);        {init to no source code position}
  sym_p^.comm_p := nil;                {init to no comments apply}
  sym_p^.symtab_p := addr(table);      {save pointer to symbol table sym is in}
  sym_p^.subscope_p := nil;            {this symbol doesn't define a scope}
  sym_p^.subtab_p := nil;              {this symbol doesn't have subordinate table}
  sym_p^.flags := [];                  {init to no modifier flags}
  sym_p^.app_p := nil;                 {init pointer private to app}
  sym_p^.symtype := code_symtype_undef_k; {init symbol to undefined}

  sys_error_none (stat);
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYM_LOOKUP (CODE, NAME, SYMTAB, SYM_P)
*
*   Look up the symbol NAME in the symbol table SYMTAB.  SYM_P is returned
*   pointing to the symbol if found, and NIL if not found.
}
procedure code_sym_lookup (            {look up symbol name in a symbol table}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to look up}
  in      symtab: code_symtab_t;       {symbol table to look up name in}
  out     sym_p: code_symbol_p_t);     {returned pointer to symbol, NIL if not found}
  val_param;

var
  name_p: string_var_p_t;              {pointer to name string in symbol table}

begin
  string_hash_ent_lookup (             {look up name in hash table}
    symtab.hash,                       {hash table to look in}
    name,                              {entry name to look for}
    name_p,                            {returned pointer to name in hash table}
    sym_p);                            {returned pointer to data for this entry}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYM_INSCOPE (CODE, NAME, SYMTYPE, SCOPE, SYM_P, STAT)
*
*   Create the symbol NAME of type SYMTYPE within the scope SCOPE.  SYM_P is
*   returned pointing to the new symbol.  It is an error if the symbol
*   already exists.  The symbol data specific to its type is not set.
}
procedure code_sym_inscope (           {create symbol in specific scope}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to create}
  in      symtype: code_symtype_k_t;   {type of symbol to create}
  in out  scope: code_scope_t;         {scope to create the symbol within}
  out     sym_p: code_symbol_p_t;      {returned pointer to new symbol}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  tab_p: code_symtab_p_t;              {to symbol table for this symbol}

begin
  tab_p := code_symtab_symtype (code, scope, symtype); {get pnt to symbol table}

  code_sym_new (code, name, tab_p^, sym_p, stat); {create the symbol}
  if sys_error(stat) then return;

  sym_p^.symtype := symtype;           {set the type of this symbol}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYM_CURR (CODE, NAME, SYMTYPE, SYM_P, STAT)
*
*   Create the symbol NAME of type SYMTYPE within the current scope.  SYM_P is
*   returned pointing to the new symbol.  It is an error if the symbol
*   already exists.  The symbol data specific to its type is not set.
}
procedure code_sym_curr (              {create symbol in current scope}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to create}
  in      symtype: code_symtype_k_t;   {type of symbol to create}
  out     sym_p: code_symbol_p_t;      {returned pointer to new symbol}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  code_sym_inscope (                   {create the symbol}
    code,                              {CODE library use state}
    name,                              {symbol name}
    symtype,                           {type of symbol to create}
    code.scope_p^,                     {scope to create symbol in}
    sym_p,                             {returned pointer to the new symbol}
    stat);                             {returned completion status}
  end;
{
********************************************************************************
*
*   Function CODE_SYMSHOW_RESOLVE (SHOW)
*
*   Returns the final fully resolved set of symbol-showing flags implied by
*   SHOW.  Some flags in SHOW may inhibit or imply others.  This function
*   returns the set of flags ultimately enabled by SHOW.
}
function code_symshow_resolve (        {resolve show flag overrides to final values}
  in      show: code_symshow_t)        {show flags to apply rules to resolve}
  :code_symshow_t;                     {fully resolved show flags}
  val_param;

var
  sh: code_symshow_t;                  {resolved flags}

begin
  sh := show;                          {init to originally enabled flags}

  if code_symshow_comm_k in show then begin
    sh := sh + [code_symshow_commeol_k];
    end;

  if code_symshow_scopes_k in show then begin
    sh := sh + [code_symshow_scope1_k];
    end;

  code_symshow_resolve := sh;          {pass back final result}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYM_SHOW (CODE, SYM, LEV, SHOW)
*
*   Write a description of the symbol SYM to standard output.
*
*   LEV is the nesting level to show the symbol at, with 0 being the top level.
*
*   The basic one-line description of the symbol is always shown.  SHOW is a set
*   of flags that enable showing additional information.  The possible flags in
*   SHOW and what they enable are:
*
*     CODE_SYMSHOW_COMMEOL_K
*
*       Show the end of line comment, if any, the symbol is tagged with.
*
*     CODE_SYMSHOW_COMM_K
*
*       Show the complete comment hierarchy for the symbol, including the end of
*       line comment.  When this flag is set, CODE_SYMSHOW_COMMEOL_K becomes
*       irrelevant, as if set.
*
*     CODE_SYMSHOW_SCOPE1_K
*
*       Show the symbols in any scopes immediately subordinate to SYM.  Put
*       another way, this shows scopes one level below SYM.
*
*     CODE_SYMSHOW_SCOPES_K
*
*       Show symbols in all subordinate scopes.  This causes the full tree of
*       symbols below SYM to be shown.  When this flag is set,
*       CODE_SYMSHOW_SCOPE1_K becomes irrelevant, as if set.
*
*     CODE_SYMSHOW_SUB_K
*
*       Show subordinate symbols that are private to SYM.  For example, this
*       would show the named fields of an aggregate data type.
}
procedure code_sym_show (              {show symbol and any subordinate tree}
  in out  code: code_t;                {CODE library use state}
  in      sym: code_symbol_t;          {symbol to show description of}
  in      lev: sys_int_machine_t;      {nesting level, 0 at top}
  in      show: code_symshow_t);       {list of optional info to show per symbol}
  val_param;

var
  tk: string_var32_t;                  {scratch token}
  showr: code_symshow_t;               {SHOW with overrides resolved}
  show2: code_symshow_t;               {scratch show flags}
  stat: sys_err_t;                     {completion status}

label
  done_sytype;

begin
  tk.max := size_char(tk.str);         {init local var string}
  showr := code_symshow_resolve (show); {resolve what to actually show}

  code_show_level_dot (lev);           {write leading indentation for this level}

  if sym.name_p = nil                  {show symbol name}
    then begin
      write ('-- No Name --');
      end
    else begin
      write (sym.name_p^.str:sym.name_p^.len);
      end
    ;
  write (': ');

  case sym.symtype of                  {which type of symbol}
code_symtype_undef_k: begin
    write ('Undefined');
    end;
code_symtype_scope_k: begin
    write ('Scope');
    end;
code_symtype_memory_k: begin
    write ('Memory');
    if sym.memory_p <> nil then begin
      write (' bitsadr ', sym.memory_p^.bitsadr);
      write (' bitsdat ', sym.memory_p^.bitsdat);
      code_show_memaccs (sym.memory_p^.accs);
      code_show_memattr (sym.memory_p^.attr);
      end;
    end;
code_symtype_memreg_k: begin
    write ('Mem region');
    if sym.memreg_p <> nil then begin
      if sym.memreg_p^.mem_p <> nil then begin
        if sym.memreg_p^.mem_p^.sym_p <> nil then begin
          if sym.memreg_p^.mem_p^.sym_p^.name_p <> nil then begin
            write (' in ', sym.memreg_p^.mem_p^.sym_p^.name_p^.str:sym.memreg_p^.mem_p^.sym_p^.name_p^.len);
            end;
          end;
        end;
      string_f_int_max_base (tk, sym.memreg_p^.adrst, 16, 0, [string_fi_unsig_k], stat);
      sys_error_abort (stat, '', '', nil, 0);
      write (' ', tk.str:tk.len);
      string_f_int_max_base (tk, sym.memreg_p^.adren, 16, 0, [string_fi_unsig_k], stat);
      sys_error_abort (stat, '', '', nil, 0);
      write ('-', tk.str:tk.len);
      code_show_memaccs (sym.memreg_p^.accs);
      end;
    end;
code_symtype_adrsp_k: begin
    write ('Adr space');
    if sym.adrsp_p <> nil then begin
      write (' bitsadr ', sym.adrsp_p^.bitsadr);
      write (' bitsdat ', sym.adrsp_p^.bitsdat);
      code_show_memaccs (sym.adrsp_p^.accs);
      end;
    end;
code_symtype_adrreg_k: begin
    write ('Adr region');
    if sym.adrreg_p <> nil then begin
      if sym.adrreg_p^.space_p <> nil then begin
        if sym.adrreg_p^.space_p^.sym_p <> nil then begin
          if sym.adrreg_p^.space_p^.sym_p^.name_p <> nil then begin
            write (' in ', sym.adrreg_p^.space_p^.sym_p^.name_p^.str:sym.adrreg_p^.space_p^.sym_p^.name_p^.len);
            end;
          end;
        end;
      string_f_int_max_base (tk, sym.adrreg_p^.adrst, 16, 0, [string_fi_unsig_k], stat);
      sys_error_abort (stat, '', '', nil, 0);
      write (' ', tk.str:tk.len);
      string_f_int_max_base (tk, sym.adrreg_p^.adren, 16, 0, [string_fi_unsig_k], stat);
      sys_error_abort (stat, '', '', nil, 0);
      write ('-', tk.str:tk.len);
      code_show_memaccs (sym.adrreg_p^.accs);
      end;
    end;
code_symtype_const_k: begin
    write ('Constant');
    end;
code_symtype_enum_k: begin
    write ('Enum val');
    end;
code_symtype_dtype_k: begin
    write ('dtype ');
    if sym.dtype_dtype_p = nil then goto done_sytype;
    code_dtype_show (code, sym.dtype_dtype_p^, lev, show);
    end;
code_symtype_field_k: begin
    write ('Field');
    end;
code_symtype_var_k: begin
    write ('Var');
    end;
code_symtype_alias_k: begin
    write ('Alias');
    end;
code_symtype_proc_k: begin
    write ('Proc');
    end;
code_symtype_prog_k: begin
    write ('Prog');
    end;
code_symtype_com_k: begin
    write ('Commblk');
    end;
code_symtype_module_k: begin
    write ('Mod');
    end;
code_symtype_label_k: begin
    write ('Lab');
    end;
otherwise
    write ('type ', ord(sym.symtype));
    end;
done_sytype:                           {done with one-line info for this symbol}
  writeln;

  if                                   {show EOL comment ?}
      (code_symshow_commeol_k in showr) and
      (sym.comm_p <> nil)
      then begin
    code_comm_show (sym.comm_p, lev + 2);
    end;

  if code_symshow_source_k in showr then begin {show source code location ?}
    code_show_pos (sym.pos, lev + 2);
    end;

  if                                   {show subordinate symbols ?}
      (code_symshow_sub_k in showr) and
      (sym.subtab_p <> nil)
      then begin
    code_symtab_show (code, sym.subtab_p^, lev + 1, show);
    end;

  if                                   {show subordinate scopes ?}
      (code_symshow_scope1_k in showr) and
      (sym.subscope_p <> nil)
      then begin
    show2 := show;                     {init what to show in subordinate levels}
    if not (code_symshow_scopes_k in showr) then begin {only show 1 level down ?}
      show2 := show2 - [code_symshow_scope1_k]; {don't show further sub-scopes}
      end;
    code_scope_show (code, sym.subscope_p^, lev + 1, show2);
    end;
  end;
