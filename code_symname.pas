{   Symbol names.
}
module code_symname;
define code_symname_path;
define code_symname_abs;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_SYMNAME_PATH (CODE, SYM, MEM, PATH_P)
*
*   Create the list of symbols that are the full path hierarchy of the symbol
*   SYM.
*
*   PATH_P is returned pointing the newly created symbols list.  The symbols
*   will be in global to local order.  The first entry will therefore be a
*   symbol in the root scope, and the last will be SYM.  This routine creates
*   the symbols list.  It is up to the caller to delete the symbols list when
*   done with it.  This is done by calling CODE_SYMLIST_DEL.
*
*   MEM is the parent memory context the symbol list will be created under.  The
*   symbol list will be automatically deleted when MEM is deleted.
}
procedure code_symname_path (          {get full symbol name path}
  in out  code: code_t;                {CODE library use state}
  var in  sym: code_symbol_t;          {symbol to get full name path of}
  in out  mem: util_mem_context_t;     {parent mem for new symbols list}
  out     path_p: code_symlist_p_t);   {symbols path, global to local order}
  val_param;

var
  sym_p: code_symbol_p_t;              {to current symbol}

begin
  code_symlist_new (mem, path_p);      {create symbols list, initialized to empty}

  sym_p := addr(sym);                  {init current symbol}
  while sym_p <> nil do begin          {back here each new parent symbol}
    code_symlist_ent_insert (path_p^, nil, sym_p^); {add this symbol to start of list}
    if sym_p^.symtab_p^.parsym_p <> nil
      then begin                       {this is a private subordinate symbol}
        sym_p := sym_p^.symtab_p^.parsym_p; {to parent symbol}
        end
      else begin                       {not a private symbol}
        sym_p := sym_p^.symtab_p^.scope_p^.symbol_p; {to symbol for parent scope}
        end
      ;
    end;                               {back to handle new symbol}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYMNAME_ABS (CODE, SYM, PATH)
*
*   Get the absolute hierarchy pathname of the symbol SYM.  The name is returned
*   in PATH.  The path is in global to local order, with individual names in the
*   path separated by ":" characters.
}
procedure code_symname_abs (           {make absolute symbol name path string}
  in out  code: code_t;                {CODE library use state}
  var in  sym: code_symbol_t;          {symbol to get full name path string of}
  in out  path: univ string_var_arg_t); {returned full symbol hiearchy path name}
  val_param;

var
  list_p: code_symlist_p_t;            {to list of symbols in path, global to local}
  ent_p: code_symlist_ent_p_t;         {to current symbols list entry}

begin
  code_symname_path (code, sym, code.mem_p^, list_p); {make list of symbols in path}

  path.len := 0;                       {init the returned string to empty}

  ent_p := list_p^.first_p;            {init current symbols list entry}
  while ent_p <> nil do begin
    if path.len > 0 then begin         {not at start of name string ?}
      string_append1 (path, ':');      {add separator after previous name}
      end;
    if ent_p^.sym_p^.name_p <> nil then begin {this symbol has a name ?}
      string_append (path, ent_p^.sym_p^.name_p^); {add name of this symbol to path}
      end;
    ent_p := ent_p^.next_p;            {to next list entry}
    end;                               {back to process this new list entry}

  code_symlist_del (list_p);           {delete the temporary symbols list}
  end;
