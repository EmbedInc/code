{   Comment handling
}
module code_comm;
define code_comm_new_block;
define code_comm_new_eol;
define code_comm_keep;
define code_comm_find;
define code_comm_show1;
define code_comm_show;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_COMM_NEW_BLOCK (CODE, STR_P, POS, LNUM, LEVEL, COMM_P)
*
*   Add the string at STR_P as a new block comment line to the system.
*
*   POS is the source position of the new comment string.  LNUM is the
*   sequential line number the comment string is on.  LEVEL is the 0-N nesting
*   level of the block comment the string is in.  COMM_P is returned pointing
*   to the new or modified comment descriptor.
*
*   If the new comment line is one line after the end of the last block comment
*   and at the same nesting level, then the line is added to that block comment.
*   Otherwise a new block comment descriptor is created and linked into the
*   system.  In either case COMM_P is returned pointing to the modified or newly
*   created block comment derscriptor.
}
procedure code_comm_new_block (        {add new block comment line to system}
  in out  code: code_t;                {CODE library use state}
  in      str_p: string_var_p_t;       {pointer to comment text}
  in      pos: fline_cpos_t;           {source position of new comment line}
  in      lnum: sys_int_machine_t;     {sequential line number}
  in      level: sys_int_machine_t;    {0-N nesting level}
  out     comm_p: code_comm_p_t);      {returned pointing to comment created or added to}
  val_param;

var
  com_p: code_comm_p_t;                {scratch pointer to comment descriptor}
  list_p: string_fwlist_p_t;           {pointer to comment lines list entry}

label
  newcomm, add_line;

begin
  comm_p := code.comm_block_p;         {get pointer to last block comment}
  if comm_p = nil then goto newcomm;   {there is no block comment ?}
  if level <> comm_p^.block_level then goto newcomm; {not same nesting level ?}
  if lnum <> (comm_p^.lnum + 1) then goto newcomm; {new line doesn't extend ?}
  goto add_line;                       {go add new line to end of block at COMM_P}
{
*   Create a new block comment from the new comment line.
}
newcomm:
  {
  *   Create the new comment block.
  }
  code_alloc_global (                  {allocate mem for new comment descriptor}
    code, sizeof(comm_p^), comm_p);
  comm_p^.prev_p := nil;               {init new comment descriptor}
  comm_p^.lnum := lnum;
  comm_p^.pos := pos;
  comm_p^.commty := code_commty_block_k;
  comm_p^.block_level := level;
  comm_p^.block_list_p := nil;
  comm_p^.block_last_p := nil;
  comm_p^.block_keep := false;
  {
  *   Link the new comment block into the current hierarchy.
  }
  com_p := code.comm_block_p;          {init to curr lowest level block comment}
  while                                {scan backwards to last comment to link onto}
      (com_p <> nil) and then (        {there is a comment here ?}
        (com_p^.block_level < level) or {still at a lower level ?}
        ((com_p^.block_level <> level) and (not com_p^.block_keep)) {same lev, not keep ?}
        )
      do begin
    com_p := com_p^.prev_p;            {back to previous comment in chain}
    end;

  if com_p <> nil then begin           {there is comment to link onto ?}
    comm_p^.prev_p := com_p;           {set link back to previous comment}
    end;
  code.comm_block_p := comm_p;         {set new comment block as latest}

add_line:                              {add the new line to the block comm at COMM_P}
  code_alloc_global (                  {allocate mem for new comment lines list entry}
    code, sizeof(list_p^), list_p);
  list_p^.next_p := nil;               {fill in new list entry}
  list_p^.str_p := str_p;
  {
  *   Link the new entry to the end of the list of comment at COMM_P.
  }
  if comm_p^.block_last_p = nil
    then begin                         {first entry in new list}
      comm_p^.block_list_p := list_p;
      end
    else begin                         {link to end of existing list}
      comm_p^.block_last_p^.next_p := list_p;
      end
    ;
  comm_p^.block_last_p := list_p;      {new entry is now at end of list}

  comm_p^.lnum := lnum;                {update source line number of last comm line}
  end;
{
********************************************************************************
*
*   Subroutine CODE_COMM_NEW_EOL (CODE, STR_P, POS, LNUM, COMM_P)
*
*   Add the string at STR_P as a new end of line comment to the system.
*
*   POS is the source position of the new comment string.  LNUM is the
*   sequential line number the comment is on.  COMM_P is returned pointing to
*   the new comment descriptor.
}
procedure code_comm_new_eol (          {add new end of line comment to system}
  in out  code: code_t;                {CODE library use state}
  in      str_p: string_var_p_t;       {pointer to comment text}
  in      pos: fline_cpos_t;           {source position of new comment line}
  in      lnum: sys_int_machine_t;     {sequential line number}
  out     comm_p: code_comm_p_t);      {returned pointing to comment created or added to}
  val_param;

begin
  code_alloc_global (code, sizeof(comm_p^), comm_p); {alloc mem for new descriptor}

  comm_p^.prev_p := code.comm_block_p; {fill in new descriptor}
  comm_p^.lnum := lnum;
  comm_p^.pos := pos;
  comm_p^.commty := code_commty_eol_k;
  comm_p^.eol_prev_p := code.comm_eol_p;
  comm_p^.eol_str_p := str_p;
  comm_p^.eol_used := false;

  code.comm_eol_p := comm_p;           {make this the latest EOL comment}
  end;
{
********************************************************************************
*
*   Subroutine CODE_COMM_KEEP (CODE, LNUM, COMM_P)
*
*   Cause the last block comment to be kept in the previously-applicable
*   comments list for its level if a new block comment at the same level is
*   added.  LNUM is the sequential line number of the last line of the block
*   comment to keep.  COMM_P is returned pointing to the block comment, if a
*   matching block comment was found.
}
procedure code_comm_keep (             {keep last block comment in previous comm list}
  in out  code: code_t;                {CODE library use state}
  in      lnum: sys_int_machine_t;     {sequential line number of last comment line in block}
  out     comm_p: code_comm_p_t);      {comment created or added to, NIL on no matching block}
  val_param;

var
  com_p: code_comm_p_t;                {scratch pointer to comment descriptor}

begin
  comm_p := nil;                       {init to no matching block comment found}
  com_p := code.comm_block_p;          {to latest block comment}
  if com_p = nil then return;          {no block comment, nothing to do ?}
  if lnum <> com_p^.lnum then return;  {doesn't apply to latest block comment ?}
  com_p^.block_keep := true;           {indicate to keep this block comm in hierarchy}
  comm_p := com_p;                     {return pointer to modified comment block}
  end;
{
********************************************************************************
*
*   Subroutine CODE_COMM_FIND (CODE, LNUM, LEVEL, COMM_P)
*
*   Find the comment descriptor that applies to a particular line of code.
}
procedure code_comm_find (             {returns pointer to comments applying at position}
  in out  code: code_t;                {CODE library use state}
  in      lnum: sys_int_machine_t;     {sequential line number}
  in      level: sys_int_machine_t;    {0-N nesting level}
  out     comm_p: code_comm_p_t);      {returned pointer to comments, may be NIL}
  val_param;

begin
{
*   Check for an end of line comment for this line.
}
  comm_p := code.comm_eol_p;           {init to latest EOL comment}
  while true do begin                  {scan backwards looking for matching EOL comment}
    if comm_p = nil then exit;         {no EOL comment, go check for block comments}
    if comm_p^.lnum = lnum then begin  {found the EOL comment for this line ?}
      if not comm_p^.eol_used then return; {this comment not already tagged something else ?}
      exit;                            {this comment already used, go check block comments}
      end;
    if comm_p^.lnum < lnum then exit;  {already past the target source line ?}
    comm_p := comm_p^.eol_prev_p;      {to previous EOL comment in list}
    end;                               {back to check this new EOL comment}
{
*   A suitable EOL comment was not found.  Check for block comments.
}
  comm_p := code.comm_block_p;         {init to latest block comment}
  while comm_p <> nil do begin         {scan backwards thru the block comments}
    if comm_p^.block_level <= level then begin {this comment applicable to curr level ?}
      code.comm_block_p := comm_p;     {make this the current latest comment}
      exit;
      end;
    comm_p := comm_p^.prev_p;          {back to previous block comment}
    end;

  end;
{
********************************************************************************
*
*   Subroutine CODE_COMM_SHOW1 (COMM, INDENT)
*
*   Show the contents of the single comment descriptor, COMM.
}
procedure code_comm_show1 (            {show contents of single comment descriptor}
  in      comm: code_comm_t;           {the comment to show contents of}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param;

var
  slent_p: string_fwlist_p_t;          {points to string list entry}

begin
  case comm.commty of                  {what type of comment is it ?}

code_commty_block_k: begin             {block comment}
      string_nblanks (indent);
      writeln ('Block comment on line ', comm.pos.line_p^.lnum,
        ', level ', comm.block_level, ':');
      slent_p := comm.block_list_p;    {init to first comment line}
      while slent_p <> nil do begin
        string_nblanks (indent+2);
        writeln ('|', slent_p^.str_p^.str:slent_p^.str_p^.len);
        slent_p := slent_p^.next_p;
        end;
      end;

code_commty_eol_k: begin               {end of line comment}
      string_nblanks (indent);
      writeln ('End of line comment:');
      string_nblanks (indent+2);
      writeln (comm.eol_str_p^.str:comm.eol_str_p^.len);
      end;

otherwise
    writeln ('Unrecognized comment of type ', ord(comm.commty));
    end;
  end;
{
********************************************************************************
*
*   Subroutine CODE_COMM_SHOW (COMM_P, INDENT)
*
*   Show the contents of the hierarchy of comments pointed to by COMM_P.  It is
*   permissible for COMM_P to be NIL.  In that case, a message is written to
*   indicate no comments.
}
procedure code_comm_show (             {show comment hierarchy on STDOUT, for debugging}
  in      comm_p: code_comm_p_t;       {pointer to comments, may be NIL}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param;

var
  com_p: code_comm_p_t;                {pointer to current comment}

begin
  if comm_p = nil then begin           {no comments ?}
    string_nblanks (indent);
    writeln ('-- no comments --');
    return;
    end;

  com_p := comm_p;                     {init to first comment in hierarchy}
  while com_p <> nil do begin          {scan up the comments hierarchy}
    code_comm_show1 (com_p^, indent);  {show this comment}
    com_p := com_p^.prev_p;            {to previous comment}
    end;
  end;
