{   Full-featured list of symbols.  These lists are double-linked and all the
*   list data is contained in a private memory context.
}
module code_symlist;
define code_symlist_new;
define code_symlist_del;
define code_symlist_ent_add;
define code_symlist_ent_insert;
define code_symlist_ent_move;
define code_symlist_sort;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_SYMLIST_NEW (MEM, LIST_P)
*
*   Create a new symbols list.  MEM is the parent memory context under which the
*   private memory context of the list will be created.  LIST_P is returned
*   pointing to the new empty symbols list.
}
procedure code_symlist_new (           {create new empty symbols list}
  in out  mem: util_mem_context_t;     {parent mem context, will create subordinate}
  out     list_p: code_symlist_p_t);   {returned pointer to new list}
  val_param;

var
  mem_p: util_mem_context_p_t;         {to private mem context for the new list}

begin
  util_mem_context_get (mem, mem_p);   {create private mem context for the list}
  util_mem_context_err_bomb (mem_p);

  util_mem_grab (                      {allocate memory for the list descriptor}
    sizeof(list_p^), mem_p^, false, list_p);
  util_mem_grab_err_bomb (list_p, sizeof(list_p^));

  list_p^.mem_p := mem_p;              {initialize the list descriptor}
  list_p^.n := 0;
  list_p^.first_p := nil;
  list_p^.last_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYMLIST_DEL (LIST_P)
*
*   Delete the symbols list pointed to by LIST_P.  All resources allocated to
*   the list will be released.  LIST_P is returned NIL.  Nothing is done when
*   LIST_P is NIL on entry.
}
procedure code_symlist_del (           {delete symbols list, deallocate resources}
  in out  list_p: code_symlist_p_t);   {to symbols list, returned NIL}
  val_param;

var
  mem_p: util_mem_context_p_t;         {saved pointer to list memory context}

begin
  if list_p = nil then return;         {no list, nothing to do ?}

  mem_p := list_p^.mem_p;              {save pointer to list memory context}
  util_mem_context_del (mem_p);        {deallocate all list memory}
  list_p := nil;                       {list no longer exists, pointer is invalid}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYMLIST_ENT_ADD (LIST, SYM)
*
*   Add the symbol SYM to the end of the symbols list LIST.
}
procedure code_symlist_ent_add (       {add new entry to the end of the list}
  in out  list: code_symlist_t;        {list to add entry to}
  in var  sym: code_symbol_t);         {symbol to add}
  val_param;

var
  ent_p: code_symlist_ent_p_t;         {to new list entry}

begin
  util_mem_grab (                      {allocate memory for the new list entry}
    sizeof(ent_p^), list.mem_p^, false, ent_p);
  util_mem_grab_err_bomb (ent_p, sizeof(ent_p));

  ent_p^.prev_p := list.last_p;        {fill in the new list entry}
  ent_p^.next_p := nil;
  ent_p^.sym_p := addr(sym);

  if list.last_p = nil
    then begin                         {this is first entry in the list}
      list.first_p := ent_p;
      end
    else begin                         {adding after an existing entry}
      list.last_p^.next_p := ent_p;
      end
    ;
  list.n := list.n + 1;                {count one more entry in the list}
  end;
{
********************************************************************************
*
*   Local subroutine INSERT (LIST, BEF_P, ENT)
*
*   Insert the entry ENT immediately after the entry at BEF_P.  ENT is inserted
*   at the start of the list when BEF_P is NIL.  The PREV_P and NEXT_P fields of
*   ENT are overwritten, with the values on entry being irrelevant.  This is a
*   low level routine that performs no other action, like updating the entry
*   count.
}
procedure insert (                     {insert entry into list}
  in out  list: code_symlist_t;        {list to add entry to}
  in      bef_p: code_symlist_ent_p_t; {to list ent to insert after, NIL for at start}
  in out  ent: code_symlist_ent_t);    {the entry to insert into the list}
  val_param;

begin
  ent.prev_p := bef_p;                 {link new entry to entry before it}

  if bef_p = nil
    then begin                         {add new entry as first in list}
      ent.next_p := list.first_p;      {link new entry to next}
      list.first_p := addr(ent);       {new entry is now first in list}
      end
    else begin                         {new entry follows an existing entry}
      ent.next_p := bef_p^.next_p;     {set new entry forwards pointer}
      bef_p^.next_p := addr(ent);      {point previous entry to new entry}
      end
    ;
  if ent.next_p = nil
    then begin                         {new entry is at end of list}
      list.last_p := addr(ent);
      end
    else begin                         {existing entry follows new entry}
      ent.next_p^.prev_p := addr(ent);
      end
    ;
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYMLIST_ENT_INSERT (LIST, BEF_P, SYM)
*
*   Add an entry for the symbol SYM to the list LIST.  The entry is added
*   immediately after the entry at BEF_P.  When BEF_P is NIL, then the new entry
*   is added to the start of the list.
}
procedure code_symlist_ent_insert (    {insert new entry at specific point in list}
  in out  list: code_symlist_t;        {list to add entry to}
  in      bef_p: code_symlist_ent_p_t; {to list ent to insert after, NIL for at start}
  in var  sym: code_symbol_t);         {symbol to add}
  val_param;

var
  ent_p: code_symlist_ent_p_t;         {to new list entry}

begin
  util_mem_grab (                      {allocate memory for the new list entry}
    sizeof(ent_p^), list.mem_p^, false, ent_p);
  util_mem_grab_err_bomb (ent_p, sizeof(ent_p));

  ent_p^.sym_p := addr(sym);           {set symbol the new entry is for}

  insert (list, bef_p, ent_p^);        {insert in list after entry at BEF_P}

  list.n := list.n + 1;                {count one more entry in the list}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYMLIST_ENT_MOVE (LIST, ENT, BEF_P)
*
*   Move the entry ENT in the symbols list LIST from its current position to
*   immediately after the entry pointed to by BEF_P.  When BEF_P is NIL, the
*   entry is moved to the start of the list.  Nothing is done if the entry is
*   already in the desired position.
}
procedure code_symlist_ent_move (      {move entry within symbols list}
  in out  list: code_symlist_t;        {list to move entry within}
  in out  ent: code_symlist_ent_t;     {the entry to move}
  in out  bef_p: code_symlist_ent_p_t); {to list ent to move after, NIL for at start}
  val_param;

begin
{
*   Return without making any changes if the entry is already at the desired
*   position.
}
  if bef_p = nil
    then begin                         {move entry to start of list}
      if ent.prev_p = nil then return; {already at start of list, nothing to do ?}
      end
    else begin                         {moving to after an existing entry}
      if ent.prev_p = bef_p then return; {already following entry at BEF_P ?}
      end
    ;
{
*   Unlink the entry from the list.
}
  if ent.prev_p = nil
    then begin                         {entry is at the start of the list}
      list.first_p := ent.next_p;
      end
    else begin                         {entry is following another entry}
      ent.prev_p^.next_p := ent.next_p;
      end
    ;

  if ent.next_p = nil
    then begin                         {entry is at the end of the list}
      list.last_p := ent.prev_p;
      end
    else begin
      ent.next_p^.prev_p := ent.prev_p;
      end
    ;
{
*   Insert the entry in its new location.
}
  insert (list, bef_p, ent);           {insert after entry at BEF_P}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SYMLIST_SORT (LIST)
*
*   Sort the entries of the symbols list LIST in alphabetical order of symbol
*   name.  Symbols with the same name will be sorted in symbol table order.  The
*   symbol table order is the order the symbol table pointers appear in within
*   the CODE_SCOPE_T descriptor.
}
procedure code_symlist_sort (          {sort list in alphabetical order}
  in out  list: code_symlist_t);       {the list to sort}
  val_param;

var
  curr_p: code_symlist_ent_p_t;        {to entry currently being resolved}
  best_p: code_symlist_ent_p_t;        {to best candidate for current entry}
  comp_p: code_symlist_ent_p_t;        {entry being compared to current}
  strcomp: sys_int_machine_t;          {string comparison result}
  tabbest, tabcomp: sys_int_adr_t;     {offset of symbol table into scope struct}

label
  new_best, next_comp;

begin
  curr_p := list.first_p;              {init current entry to first}
  if curr_p = nil then return;         {no entries, nothing to sort ?}
  while curr_p^.next_p <> nil do begin {loop over all but last list entry}
    best_p := curr_p;                  {init to best entry is the current}

    comp_p := curr_p^.next_p;          {init first entry to compare against}
    while comp_p <> nil do begin       {loop over remaining list entries}
      {
      *   Compare symbol names.  This section jumps to NEW_BEST or NEXT_COMP if
      *   the sort order is definitive from the symbol names.  Otherwise it
      *   continues on.
      }
      if best_p^.sym_p^.name_p = nil
        then begin                     {current symbol has no name ?}
          if comp_p^.sym_p^.name_p <> nil {comparison symbol does have name ?}
            then goto next_comp;
          end
        else begin                     {the current symbol has a name}
          if comp_p^.sym_p^.name_p = nil {comparison symbol has no name}
            then goto new_best;
          strcomp :=  string_compare ( {compare the two symbol names}
            best_p^.sym_p^.name_p^, comp_p^.sym_p^.name_p^);
          if strcomp < 0 then goto next_comp; {COMP is before BEST}
          if strcomp > 0 then goto new_best; {COMP is after BEST}
          end
        ;
      {
      *   Unable to resolve the sort order by the symbol names.
      *
      *   Sort by postion of the symbol table within the scope structure.
      }
      tabbest :=                       {symbol table offset for BEST}
        sys_int_adr_t(best_p^.sym_p^.symtab_p) -
        sys_int_adr_t(best_p^.sym_p^.symtab_p^.scope_p);
      tabcomp :=                       {symbol table offset for COMP}
        sys_int_adr_t(comp_p^.sym_p^.symtab_p) -
        sys_int_adr_t(comp_p^.sym_p^.symtab_p^.scope_p);
      if tabbest <= tabcomp then goto next_comp; {already in sort order ?}

new_best:                              {the symbol at COMP_P is better than current}
      best_p := comp_p;                {update best option found so far}

next_comp:                             {advance to the next entry to compare against}
      comp_p := comp_p^.next_p;        {to next entry}
      end;                             {back to compare against this new entry}

    if best_p = curr_p
      then begin                       {no better entry found ?}
        curr_p := curr_p^.next_p;      {advance to next entry}
        end
      else begin                       {replace curr entry with ent at BEST_P}
        code_symlist_ent_move (        {move best entry to before current}
          list, best_p^, curr_p^.prev_p);
        end
      ;
    end;                               {back to do entry at CURR_P}
  end;
