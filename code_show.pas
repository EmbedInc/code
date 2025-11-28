{   Show information to the user.
}
module code_show;
define code_show_pos;
define code_show_pos_parse;
define code_show_level_blank;
define code_show_level_dot;
define code_show_memaccs;
define code_show_memattr;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Local subroutine SHOW_COLL_LINE (COLL, LNUM, LEV)
*
*   Show the collection name and the line number within the collection.
}
procedure show_coll_line (             {show collection and line within}
  in      coll: fline_coll_t;          {collection line is within}
  in      lnum: sys_int_machine_t;     {line number within collection}
  in      lev: sys_int_machine_t);     {nesting level to show data at}
  val_param; internal;

begin
  if coll.name_p = nil then return;    {collection has no name ?}
  if coll.name_p^.len <= 0 then return; {collection name is empty ?}

  code_show_level_blank (lev);
  writeln ('From "', coll.name_p^.str:coll.name_p^.len, '" line ', lnum);
  end;
{
********************************************************************************
*
*   Subroutine CODE_SHOW_POS (POS, LEV)
*
*   Show the source code location indicated by POS.  Leading blanks are written
*   according to the nesting level LEV.
}
procedure code_show_pos (              {show source code position}
  in      pos: fline_cpos_t;           {character position to show}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param;

var
  lpos_p: fline_lpos_p_t;              {to current logical line in hierarchy}
  coll_p: fline_coll_p_t;              {to current collection in hierarch}
  logshown: boolean;                   {at least one logical position was shown}

label
  nvirt;

begin
  if pos.line_p = nil then return;     {source line not known, nothing to do ?}
{
*   Show the virtual line info, if available.
}
  if pos.line_p^.virt_p = nil          {no virtual line available ?}
    then goto nvirt;
  coll_p := pos.line_p^.virt_p^.coll_p; {get pointer to collection}

  if coll_p = nil                      {collection virt line is in unknown ?}
    then goto nvirt;
  if coll_p^.name_p = nil              {virtual collection has no name ?}
    then goto nvirt;
  if coll_p^.name_p^.len <= 0          {virtual coll name is empty ?}
    then goto nvirt;

  show_coll_line (                     {show collection name and line number}
    coll_p^,                           {collection}
    pos.line_p^.virt_p^.lnum,          {line number within the collection}
    lev);                              {nesting level}
  return;

nvirt:                                 {virtual line info not available}
{
*   Show the logical line info, if available.
}
  logshown := false;                   {init to no logical position shown}
  lpos_p := pos.line_p^.lpos_p;        {init to lowest level logical position}

  while lpos_p <> nil do begin         {up the logical hierarchy}
    if lpos_p^.line_p = nil then exit;
    coll_p := lpos_p^.line_p^.coll_p;  {get pointer to collection at this level}
    if                                 {this collection has a name ?}
        (coll_p^.name_p <> nil) and then
        (coll_p^.name_p^.len > 0)
        then begin
      show_coll_line (                 {show location at this hiearchy level}
        coll_p^,                       {collection}
        lpos_p^.line_p^.lnum,          {line number within the collection}
        lev);                          {nesting level}
      logshown := true;                {logical position was shown}
      end;
    lpos_p := lpos_p^.prev_p;          {to next logical level up}
    end;                               {back to show next level up}

  if logshown then return;             {showed logical hierarchy, all done ?}
{
*   Show the physical line info, if available.
}
  if pos.line_p^.coll_p = nil then return; {collection is unknown ?}

  show_coll_line (                     {show collection name and line number}
    pos.line_p^.coll_p^,               {collection}
    pos.line_p^.lnum,                  {line number within the collection}
    lev);                              {nesting level}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SHOW_POS_PARSE (CODE)
*
*   Show the current parsing position within the input files.  When possible,
*   the current line is shown with a pointer to the current character.
}
procedure code_show_pos_parse (        {show the current parsing position on STDOUT}
  in out  code: code_t);               {CODE library use state}
  val_param;

begin
  fline_cpos_show (code.parse.pos);    {show the current parsing position}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SHOW_LEVEL_BLANK (LEV)
*
*   Indent to show the nesting level LEV.  LEV of 0 indicates the top (root)
*   level, with higher values successive levels subordinate to the top.
*
*   Only blanks are written.
}
procedure code_show_level_blank (      {indent to nesting level, write blanks only}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param;

begin
  string_nblanks (lev * 2);
  end;
{
********************************************************************************
*
*   Subroutine CODE_SHOW_LEVEL_DOT (LEV)
*
*   Indent to show the nesting level LEV.  LEV of 0 indicates the top (root)
*   level, with higher values successive levels subordinate to the top.
*
*   One dot is shown for each nested level.
}
procedure code_show_level_dot (        {indent to nesting level, show dot per level}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param;

var
  ii: sys_int_machine_t;               {loop counter}

begin
  if lev <= 0 then return;             {don't indent at all ?}
  write ('  ');                        {indent the first level}
  for ii := 2 to lev do begin          {once for each remaining level}
    write ('. ');
    end;
  end;
{
********************************************************************************
*
*   Subroutine CODE_SHOW_MEMACCS (ACCS)
*
*   Show the enabled memory accesses in ACCS.  A short name is shown for each
*   enabled access, preceded by a blank.  No end of line is written.
}
procedure code_show_memaccs (          {write short names for each enabled mem access}
  in      accs: code_memaccs_t);       {set of memory access to show}
  val_param;

begin
  if code_memaccs_rd_k in accs then write (' RD');
  if code_memaccs_wr_k in accs then write (' WR');
  if code_memaccs_ex_k in accs then write (' EX');
  end;
{
********************************************************************************
*
*   Subroutine CODE_SHOW_MEMATTR (ATTR)
*
*   Show the enabled memory attributes in ACCS.  A short name is shown for each
*   enabled attribute, preceded by a blank.  No end of line is written.
}
procedure code_show_memattr (          {write short names for each enabled mem attribute}
  in      attr: code_memattr_t);       {set of memory attributes to show}
  val_param;

begin
  if code_memattr_nv_k in attr then write (' NV');
  end;
