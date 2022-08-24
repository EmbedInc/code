{   Procedural interface to memories, memory regions, address spaces, and
*   address regions.  Names of all these entities are in the same single global
*   symbol table.
}
module code_memadr;
define code_memsym_find;
define code_mem_new;
define code_mem_find;
define code_memreg_new;
define code_memreg_find;
define code_adrsp_new;
define code_adrsp_find;
define code_adrreg_new;
define code_adrreg_find;
define code_memsym_show;
define code_memsym_show_all;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Local function MEMSYM_FIND (CODE, NAME, POS)
*
*   Returns the position of the name NAME in the memory symbol table.  The
*   function returns TRUE iff the name already exists in the symbol table.
}
function memsym_find (                 {find position of name in symbol table}
  in      code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name to look up}
  out     pos: string_hash_pos_t)      {returned position handle}
  :boolean;                            {name exists, POS at named entry}
  val_param; internal;

var
  found: boolean;                      {entry found in symbol table}

begin
  string_hash_pos_lookup (             {look up name in symbol table}
    code.memsym,                       {symbol table}
    name,                              {name to look up in symbol table}
    pos,                               {return position for the name}
    found);                            {entry exists}

  memsym_find := found;
  end;
{
********************************************************************************
*
*   Local subroutine MEMSYM_GET (POS, DATA_P)
*
*   Get the symbol information for the existing symbol at the symbol table
*   position POS.
*
*   WARNING:  This is a low level routine.  POS must be the result of a lookup
*     that found a symbol.  This is not checked.
}
procedure memsym_get (                 {get info of existing symbol table entry}
  in      pos: string_hash_pos_t;      {symbol table position, must be at symbol}
  out     data_p: code_memadr_sym_p_t); {returned pointing to data in symbol table}
  val_param; internal;

var
  name_p: string_var_p_t;              {pointer to name string in symbol table}

begin
  string_hash_ent_atpos (pos, name_p, data_p); {get the data at the position}
  end;
{
********************************************************************************
*
*   Local subroutine MEMSYM_ADD (POS, DATA_P)
*
*   Add the memory symbol table entry according to the previously-determined
*   position POS.  DATA_P is returned pointing to the data for the new symbol in
*   the symbol table.
*
*   WARNING:  This is a low level routine.  POS must be the result of a lookup
*     that did not find the name already in the symbol table.  This is not
*     checked.
}
procedure memsym_add (                 {add symbol to table}
  in out  pos: string_hash_pos_t;      {state from name lookup}
  out     data_p: code_memadr_sym_p_t); {returned pointer to data in symbol table}
  val_param; internal;

var
  name_p: string_var_p_t;              {points to symbol name in symbol table}

begin
  string_hash_ent_add (                {add the new entry to the symbol table}
    pos,                               {position and other data about entry to add}
    name_p,                            {pointer to name in symbol table}
    data_p);                           {pointer to data for the new symbol}

  data_p^.name_p := name_p;            {save pointer to name in symbol table}
  fline_cpos_init (data_p^.pos);       {init to no source position known}
  data_p^.comm_p := nil;               {init to no comments on this symbol}
  data_p^.symtype := code_symtype_undef_k; {init symbol type to undefined}
  end;
{
********************************************************************************
*
*   Local subroutine MEMSYM_NEW (CODE, NAME, MEMSYM_P, STAT)
*
*   Create the new memory symbol NAME.  It is an error if name is already used
*   for a memory, address space, or mem/adr range.  MEMSYM_P is returned
*   pointing to the data for the new symbol in the symbol table.  On error,
*   MEMSYM_P is returned NIL, and STAT set to indicate the error.
}
procedure memsym_new (                 {create new symbol in mem symbol table}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to create}
  out     memsym_p: code_memadr_sym_p_t; {returned pointer to new symbol data}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

var
  pos: string_hash_pos_t;              {position within the symbol table}
  sym_p: code_memadr_sym_p_t;          {points to symbol data in symbol table}

begin
  sys_error_none (stat);               {init to no error encountered}

  if memsym_find (code, name, pos) then begin {symbol already exists ?}
    memsym_p := nil;                   {not returning with new memory}
    memsym_get (pos, sym_p);           {get data on pre-existing symbol}
    sys_stat_set (code_subsys_k, code_stat_memsym_exist_k, stat);
    sys_stat_parm_vstr (name, stat);   {add symbol name}
    fline_stat_lnum_fnam (stat, sym_p^.pos); {add line number and file name}
    return;
    end;

  memsym_add (pos, memsym_p);          {create the generic memory symbol}
  end;
{
********************************************************************************
*
*   Subroutine CODE_MEMSYM_FIND (CODE, NAME, MEMSYM_P)
*
*   Look up NAME in the memories and address spaces symbol table.  MEMSYM_P is
*   returned pointing to the symbol data in the symbol table if the entry
*   exists.  If not, MEMSYM_P is returned NIL.
}
procedure code_memsym_find (           {find mem, mem region, adr, adr region by name}
  in      code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of mem/adr symbol to find}
  out     memsym_p: code_memadr_sym_p_t); {returned pointer to symbol, NIL if none}
  val_param;

var
  name_p: string_var_p_t;              {pointer to name in symbol table}

begin
  string_hash_ent_lookup (             {look up name in symbol table}
    code.memsym,                       {symbol table}
    name,                              {name of symbol to look up}
    name_p,                            {returned pointer to name in sym table}
    memsym_p);                         {returned pointer to data in sym table}
  end;
{
********************************************************************************
*
*   Subroutine CODE_MEM_NEW (CODE, NAME, MEM_P, STAT)
*
*   Create a new memory.  It is an error if the name is already in use as a
*   memory, address, or mem/adr region.  MEM_P is returned pointing to the new
*   memory descriptor, which is initialized to the extent possible.
}
procedure code_mem_new (               {create a new named memory}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of new memory}
  out     mem_p: code_memory_p_t;      {returned pointer to the memory, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  sym_p: code_memadr_sym_p_t;          {pointer to new symbol data in symbol table}

begin
  memsym_new (code, name, sym_p, stat); {create just the bare new symbol}
  if sys_error(stat) then return;

  util_mem_grab (                      {alloc mem for memory descriptor}
    sizeof(mem_p^), code.mem_p^, false, mem_p);

  sym_p^.symtype := code_symtype_memory_k; {new symbol is for a memory}
  sym_p^.memory_p := mem_p;

  mem_p^.sym_p := sym_p;
  mem_p^.region_p := nil;
  mem_p^.bitsadr := 0;
  mem_p^.bitsdat := 0;
  mem_p^.attr := [];
  end;
{
********************************************************************************
*
*   Subroutine CODE_MEM_FIND (CODE, NAME, MEM_P, STAT)
*
*   Return MEM_P pointing to the memory of name NAME.  It is an error if NAME
*   refers to other than a memory, or NAME is not defined.  In case of error,
*   MEM_P is returned NIL.
}
procedure code_mem_find (              {find memory by name, error if not exist}
  in      code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of memory to find}
  out     mem_p: code_memory_p_t;      {returned pointer to the memory, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  pos: string_hash_pos_t;              {position within symbol table}
  sym_p: code_memadr_sym_p_t;          {pointer to symbol data in symbol table}

begin
  sys_error_none (stat);               {init to no error}

  if not memsym_find (code, name, pos) then begin {try to find the symbol}
    sys_stat_set (code_subsys_k, code_stat_nomem_k, stat);
    sys_stat_parm_vstr (name, stat);
    mem_p := nil;
    return;
    end;

  memsym_get (pos, sym_p);             {get pointer to the symbol data}
  if sym_p^.symtype <> code_symtype_memory_k then begin {not a memory ?}
    sys_stat_set (code_subsys_k, code_stat_notmem_k, stat);
    sys_stat_parm_vstr (name, stat);
    mem_p := nil;
    return;
    end;

  mem_p := sym_p^.memory_p;            {return pointer to the memory}
  end;
{
********************************************************************************
*
*   Subroutine CODE_MEMREG_NEW (CODE, NAME, MEMNAME, MEMREG_P, STAT)
*
*   Create a new memory region.  It is an error if the name is already in use as
*   a memory, address, or mem/adr region.  MEM_P is returned pointing to the new
*   memory region descriptor, which is initialized to the extent possible.
}
procedure code_memreg_new (            {create a new named memory region}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of new memory region}
  in      memname: univ string_var_arg_t; {name of memory this region is within}
  out     memreg_p: code_memregion_p_t; {returned pointer to the mem region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  sym_p: code_memadr_sym_p_t;          {pointer to new symbol data in symbol table}
  mem_p: code_memory_p_t;              {pointer to parent memory}

begin
  memsym_new (code, name, sym_p, stat); {create just the bare new symbol}
  if sys_error(stat) then return;

  util_mem_grab (                      {alloc mem for memory region descriptor}
    sizeof(memreg_p^), code.mem_p^, false, memreg_p);

  sym_p^.symtype := code_symtype_memreg_k; {new symbol is for a memory region}
  sym_p^.memreg_p := memreg_p;

  memreg_p^.next_p := nil;             {init the memory region descriptor}
  memreg_p^.sym_p := sym_p;
  memreg_p^.mem_p := nil;
  memreg_p^.adrst := 0;
  memreg_p^.adren := 0;
  memreg_p^.attr := [];
{
*   Link to the memory this region is within, and add this region to the list of
*   regions within the memory.
}
  code_mem_find (code, memname, mem_p, stat); {get pointer to parent memory}
  if sys_error(stat) then return;
  memreg_p^.mem_p := mem_p;            {link mem region to its parent memory}

  memreg_p^.next_p := mem_p^.region_p; {add to list of regions in parent memory}
  mem_p^.region_p := memreg_p;
  end;
{
********************************************************************************
*
*   Subroutine CODE_MEMREG_FIND (CODE, NAME, MEMREG_P, STAT)
*
*   Return MEMREG_P pointing to the memory region of name NAME.  It is an error
*   if NAME refers to other than a memory region, or NAME is not defined.  In
*   case of error, MEMREG_P is returned NIL.
}
procedure code_memreg_find (           {find memory region by name, error if not exist}
  in      code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of memory region to find}
  out     memreg_p: code_memregion_p_t; {returned pointer to the mem region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  pos: string_hash_pos_t;              {position within symbol table}
  sym_p: code_memadr_sym_p_t;          {pointer to symbol data in symbol table}

begin
  sys_error_none (stat);               {init to no error}

  if not memsym_find (code, name, pos) then begin {try to find the symbol}
    sys_stat_set (code_subsys_k, code_stat_nomemreg_k, stat);
    sys_stat_parm_vstr (name, stat);
    memreg_p := nil;
    return;
    end;

  memsym_get (pos, sym_p);             {get pointer to the symbol data}
  if sym_p^.symtype <> code_symtype_memreg_k then begin {not a memory region ?}
    sys_stat_set (code_subsys_k, code_stat_notmemreg_k, stat);
    sys_stat_parm_vstr (name, stat);
    memreg_p := nil;
    return;
    end;

  memreg_p := sym_p^.memreg_p;         {return pointer to the memory region}
  end;
{
********************************************************************************
*
*   Subroutine CODE_ADRSP_NEW (CODE, NAME, ADRSP_P, STAT)
*
*   Create a new address space.  It is an error if the name is already in use as
*   a memory, address, or mem/adr region.  ADRSP_P is returned pointing to the
*   new address space descriptor, which is initialized to the extent possible.
}
procedure code_adrsp_new (             {create a new named address space}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of new adr space}
  out     adrsp_p: code_adrspace_p_t;  {returned pointer to the adr space, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  sym_p: code_memadr_sym_p_t;          {pointer to new symbol data in symbol table}

begin
  memsym_new (code, name, sym_p, stat); {create just the bare new symbol}
  if sys_error(stat) then return;

  util_mem_grab (                      {alloc mem for address space descriptor}
    sizeof(adrsp_p^), code.mem_p^, false, adrsp_p);

  sym_p^.symtype := code_symtype_adrsp_k; {new symbol is for an address space}
  sym_p^.adrsp_p := adrsp_p;

  adrsp_p^.sym_p := sym_p;
  adrsp_p^.region_p := nil;
  adrsp_p^.bitsadr := 0;
  adrsp_p^.bitsdat := 0;
  adrsp_p^.attr := [];
  end;
{
********************************************************************************
*
*   Subroutine CODE_ADRSP_FIND (CODE, NAME, ADRSP_P, STAT)
*
*   Return ADRSP_P pointing to the address space of name NAME.  It is an error
*   if NAME refers to other than an address space, or NAME is not defined.  In
*   case of error, ADRSP_P is returned NIL.
}
procedure code_adrsp_find (            {find adr space by name, error if not exist}
  in      code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of adr space to find}
  out     adrsp_p: code_adrspace_p_t;  {returned pointer to the adr space, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  pos: string_hash_pos_t;              {position within symbol table}
  sym_p: code_memadr_sym_p_t;          {pointer to symbol data in symbol table}

begin
  sys_error_none (stat);               {init to no error}

  if not memsym_find (code, name, pos) then begin {try to find the symbol}
    sys_stat_set (code_subsys_k, code_stat_noadrsp_k, stat);
    sys_stat_parm_vstr (name, stat);
    adrsp_p := nil;
    return;
    end;

  memsym_get (pos, sym_p);             {get pointer to the symbol data}
  if sym_p^.symtype <> code_symtype_adrsp_k then begin {not an address space ?}
    sys_stat_set (code_subsys_k, code_stat_notadrsp_k, stat);
    sys_stat_parm_vstr (name, stat);
    adrsp_p := nil;
    return;
    end;

  adrsp_p := sym_p^.adrsp_p;           {return pointer to the memory region}
  end;
{
********************************************************************************
*
*   Subroutine CODE_ADRREG_NEW (CODE, NAME, ADRREG_P, STAT)
*
*   Create a new address region.  It is an error if the name is already in use
*   as a memory, address, or mem/adr region.  ADRREG_P is returned pointing to
*   the new address region descriptor, which is initialized to the extent
*   possible.
}
procedure code_adrreg_new (            {create a new named address region}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of new adr region}
  in      adrname: univ string_var_arg_t; {name of address space this region is within}
  out     adrreg_p: code_adrregion_p_t; {returned pointer to the adr region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  sym_p: code_memadr_sym_p_t;          {pointer to new symbol data in symbol table}
  adr_p: code_adrspace_p_t;            {pointer to parent address space}

begin
  memsym_new (code, name, sym_p, stat); {create just the bare new symbol}
  if sys_error(stat) then return;

  util_mem_grab (                      {alloc mem for address space descriptor}
    sizeof(adrreg_p^), code.mem_p^, false, adrreg_p);

  sym_p^.symtype := code_symtype_adrreg_k; {new symbol is for a address region}
  sym_p^.adrreg_p := adrreg_p;

  adrreg_p^.next_p := nil;
  adrreg_p^.sym_p := sym_p;
  adrreg_p^.space_p := nil;
  adrreg_p^.adrst := 0;
  adrreg_p^.adren := 0;
  adrreg_p^.memreg_p := nil;
  adrreg_p^.attr := [];
{
*   Link to the address space this region is within, and add this region to the
*   list of regions within the address space.
}
  code_adrsp_find (code, adrname, adr_p, stat); {get pointer to parent adr space}
  if sys_error(stat) then return;
  adrreg_p^.space_p := adr_p;          {link adr region to its parent adr space}

  adrreg_p^.next_p := adr_p^.region_p; {add to list of regions in parent adr space}
  adr_p^.region_p := adrreg_p;
  end;
{
********************************************************************************
*
*   Subroutine CODE_ADRREG_FIND (CODE, NAME, ADRREG_P, STAT)
*
*   Return ADRREG_P pointing to the address region of name NAME.  It is an error
*   if NAME refers to other than an address region, or NAME is not defined.  In
*   case of error, ADRREG_P is returned NIL.
}
procedure code_adrreg_find (           {find adr region by name, error if not exist}
  in      code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of adr region to find}
  out     adrreg_p: code_adrregion_p_t; {returned pointer to the adr region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  pos: string_hash_pos_t;              {position within symbol table}
  sym_p: code_memadr_sym_p_t;          {pointer to symbol data in symbol table}

begin
  sys_error_none (stat);               {init to no error}

  if not memsym_find (code, name, pos) then begin {try to find the symbol}
    sys_stat_set (code_subsys_k, code_stat_noadrreg_k, stat);
    sys_stat_parm_vstr (name, stat);
    adrreg_p := nil;
    return;
    end;

  memsym_get (pos, sym_p);             {get pointer to the symbol data}
  if sym_p^.symtype <> code_symtype_adrreg_k then begin {not an address space ?}
    sys_stat_set (code_subsys_k, code_stat_notadrreg_k, stat);
    sys_stat_parm_vstr (name, stat);
    adrreg_p := nil;
    return;
    end;

  adrreg_p := sym_p^.adrreg_p;         {return pointer to the memory region}
  end;
{
********************************************************************************
*
*   Local subroutine SHOW_ATTR (ATTR, INDENT)
*
*   Show the attributes ATTR.
}
procedure show_attr (                  {show attributes}
  in      attr: code_memattr_t;        {attributes to show}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param; internal;

begin
  string_nblanks (indent);
  write ('Access:');
  if code_memattr_rd_k in attr then write (' READ');
  if code_memattr_wr_k in attr then write (' WRITE');
  if code_memattr_nv_k in attr then write (' NON-VOLATILE');
  if code_memattr_ex_k in attr then write (' EXECUTE');
  writeln;
  end;
{
********************************************************************************
*
*   Subroutine CODE_MEMSYM_SHOW (SYM, INDENT)
*
*   Show the details of the memory/address symbol SYM.
}
procedure code_memsym_show (           {show details of one mem/adr symbol}
  in      sym: code_memadr_sym_t;      {mem/adr symbol to show data of}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param;

var
  mreg_p: code_memregion_p_t;          {pointer to memory region}
  areg_p: code_adrregion_p_t;          {pointer to address region}
  mreg_ent_p: code_memreg_ent_p_t;     {pointer to memory region list entry}
  tk: string_var32_t;                  {scratch token}

begin
  tk.max := size_char(tk.str);         {init local var string}

  case sym.symtype of

code_symtype_memory_k: begin           {memory}
      string_nblanks (indent);
      writeln ('MEMORY "', sym.name_p^.str:sym.name_p^.len, '"');

      string_nblanks (indent+2);
      write ('Regions:');
      mreg_p := sym.memory_p^.region_p;
      while mreg_p <> nil do begin
        write (' ', mreg_p^.sym_p^.name_p^.str:mreg_p^.sym_p^.name_p^.len);
        mreg_p := mreg_p^.next_p;
        end;
      writeln;

      string_nblanks (indent+2);
      writeln ('Address bits ', sym.memory_p^.bitsadr,
        ' Data bits ', sym.memory_p^.bitsdat);

      show_attr (sym.memory_p^.attr, indent+2);
      end;

code_symtype_memreg_k: begin           {memory region}
      string_nblanks (indent);
      writeln ('MEMORY REGION "', sym.name_p^.str:sym.name_p^.len, '" in memory "',
        sym.memreg_p^.mem_p^.sym_p^.name_p^.str:sym.memreg_p^.mem_p^.sym_p^.name_p^.len, '"');

      string_nblanks (indent+2);
      write ('Address range ');
      string_f_int32h (tk, sym.memreg_p^.adrst);
      write (tk.str:tk.len, 'h to ');
      string_f_int32h (tk, sym.memreg_p^.adren);
      write (tk.str:tk.len, 'h, Length ');
      string_f_int32h (tk, sym.memreg_p^.adren - sym.memreg_p^.adrst + 1);
      writeln (tk.str:tk.len, 'h');

      show_attr (sym.memreg_p^.attr, indent+2);
      end;

code_symtype_adrsp_k: begin            {address space}
      string_nblanks (indent);
      writeln ('ADDRESS SPACE "', sym.name_p^.str:sym.name_p^.len, '"');

      string_nblanks (indent+2);
      write ('Regions:');
      areg_p := sym.adrsp_p^.region_p;
      while areg_p <> nil do begin
        write (' ', areg_p^.sym_p^.name_p^.str:areg_p^.sym_p^.name_p^.len);
        areg_p := areg_p^.next_p;
        end;
      writeln;

      string_nblanks (indent+2);
      writeln ('Address bits ', sym.adrsp_p^.bitsadr,
        ' Data bits ', sym.adrsp_p^.bitsdat);

      show_attr (sym.adrsp_p^.attr, indent+2);
      end;

code_symtype_adrreg_k: begin           {address region}
      string_nblanks (indent);
      writeln ('ADDRESS REGION "', sym.name_p^.str:sym.name_p^.len, '" in address space "',
        sym.adrreg_p^.space_p^.sym_p^.name_p^.str:sym.adrreg_p^.space_p^.sym_p^.name_p^.len, '"');

      string_nblanks (indent+2);
      write ('Address range ');
      string_f_int32h (tk, sym.adrreg_p^.adrst);
      write (tk.str:tk.len, 'h to ');
      string_f_int32h (tk, sym.adrreg_p^.adren);
      write (tk.str:tk.len, 'h, Length ');
      string_f_int32h (tk, sym.adrreg_p^.adren - sym.adrreg_p^.adrst + 1);
      writeln (tk.str:tk.len, 'h');

      string_nblanks (indent+2);
      write ('Mapped to mem regions:');
      mreg_ent_p := sym.adrreg_p^.memreg_p;
      while mreg_ent_p <> nil do begin
        write (' ', mreg_ent_p^.region_p^.sym_p^.name_p^.str:mreg_ent_p^.region_p^.sym_p^.name_p^.len);
        mreg_ent_p := mreg_ent_p^.next_p;
        end;
      writeln;

      show_attr (sym.adrsp_p^.attr, indent+2);
      end;

    end;                               {end of memory/address symbol type cases}

  if sym.comm_p <> nil then begin
    string_nblanks (indent+2);
    writeln ('Comments:');
    code_comm_show (sym.comm_p, indent+4);
    end;
  end;
{
********************************************************************************
*
*   Subroutine CODE_MEMSYM_SHOW_ALL (CODE, INDENT)
*
*   Show the details of all memory/address symbols that are currently defined.
}
procedure code_memsym_show_all (       {show details of all mem/adr symbols}
  in out  code: code_t;                {CODE library use state}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param;

var
  pos: string_hash_pos_t;              {position into symbol table}
  found: boolean;                      {symbol table entry exists}
  name_p: string_var_p_t;              {pointer to symbol name in symbol table}
  sym_p: code_memadr_sym_p_t;          {pointer to symbol data in symbol table}

begin
  string_hash_pos_first (code.memsym, pos, found); {to first symbol table entry}
  while found do begin                 {loop over all symbols in symbol table}
    string_hash_ent_atpos (pos, name_p, sym_p); {get data for this table entry}
    code_memsym_show (sym_p^, indent); {show this symbol}
    string_hash_pos_next (pos, found); {to next symbol in symbol table}
    end;
  end;
