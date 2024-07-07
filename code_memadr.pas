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
define code_memreg_list_add;
define code_adrreg_memreg_add;
define code_memsym_show;
define code_memsym_show_all;
%include 'code2.ins.pas';
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
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of mem/adr symbol to find}
  out     memsym_p: code_symbol_p_t);  {returned pointer to symbol, NIL if none}
  val_param;

begin
  code_sym_lookup (code, name, code.memsym_p^, memsym_p);
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
  sym_p: code_symbol_p_t;              {pointer to new symbol data in symbol table}

begin
  mem_p := nil;                        {init to new mem not created}

  code_sym_new (                       {create the new memory symbol}
    code,                              {CODE library use state}
    name,                              {name of symbol to create}
    code.memsym_p^,                    {symbol table to add symbol to}
    sym_p,                             {returned pointer to new symbol}
    stat);
  if sys_error(stat) then return;

  sym_p^.symtype := code_symtype_memory_k; {new symbol is for a memory}
  util_mem_grab (                      {alloc mem for memory descriptor}
    sizeof(mem_p^), code.memsym_p^.mem_p^, false, mem_p);
  util_mem_grab_err_bomb (mem_p, sizeof(mem_p^));
  sym_p^.memory_p := mem_p;            {point symbol to new memory descriptor}

  mem_p^.sym_p := sym_p;
  mem_p^.region_p := nil;
  mem_p^.bitsadr := 0;
  mem_p^.bitsdat := 0;
  mem_p^.accs := [];
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
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of memory to find}
  out     mem_p: code_memory_p_t;      {returned pointer to the memory, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  sym_p: code_symbol_p_t;              {pointer to the memory symbol}

begin
  sys_error_none (stat);               {init to no error}
  mem_p := nil;                        {init to memory not found}

  code_sym_lookup (                    {look up name in memories symbol table}
    code,                              {CODE library use state}
    name,                              {name of symbol to look up}
    code.memsym_p^,                    {symbol table to look in}
    sym_p);                            {returned pointer to symbol, NIL = not found}
  if sym_p = nil then begin            {no such memory symbol ?}
    sys_stat_set (code_subsys_k, code_stat_nomem_k, stat);
    sys_stat_parm_vstr (name, stat);
    return;
    end;

  if sym_p^.symtype <> code_symtype_memory_k then begin {symbol is not a memory ?}
    sys_stat_set (code_subsys_k, code_stat_notmem_k, stat);
    sys_stat_parm_vstr (name, stat);
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
  sym_p: code_symbol_p_t;              {pointer to new symbol data in symbol table}
  mem_p: code_memory_p_t;              {to memory this region is in}

begin
  memreg_p := nil;                     {init to no new region created}

  code_sym_new (                       {create the new memory symbol}
    code,                              {CODE library use state}
    name,                              {name of symbol to create}
    code.memsym_p^,                    {symbol table to add symbol to}
    sym_p,                             {returned pointer to new symbol}
    stat);
  if sys_error(stat) then return;

  sym_p^.symtype := code_symtype_memreg_k; {new symbol is for a memory region}
  util_mem_grab (                      {alloc mem for memregion descriptor}
    sizeof(memreg_p^), code.memsym_p^.mem_p^, false, memreg_p);
  util_mem_grab_err_bomb (memreg_p, sizeof(memreg_p^));
  sym_p^.memreg_p := memreg_p;         {point symbol to new memory descriptor}

  memreg_p^.next_p := nil;             {init the memory region descriptor}
  memreg_p^.sym_p := sym_p;
  memreg_p^.mem_p := nil;
  memreg_p^.adrst := 0;
  memreg_p^.adren := 0;
  memreg_p^.accs := [];
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
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of memory region to find}
  out     memreg_p: code_memregion_p_t; {returned pointer to the mem region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  sym_p: code_symbol_p_t;              {pointer to symbol data in symbol table}

begin
  sys_error_none (stat);               {init to no error}
  memreg_p := nil;                     {init to not returning with memory region}

  code_sym_lookup (                    {look up name in memories symbol table}
    code,                              {CODE library use state}
    name,                              {name of symbol to look up}
    code.memsym_p^,                    {symbol table to look in}
    sym_p);                            {returned pointer to symbol, NIL = not found}
  if sym_p = nil then begin
    sys_stat_set (code_subsys_k, code_stat_nomemreg_k, stat);
    sys_stat_parm_vstr (name, stat);
    memreg_p := nil;
    return;
    end;

  if sym_p^.symtype <> code_symtype_memreg_k then begin {symbol not a mem region ?}
    sys_stat_set (code_subsys_k, code_stat_notmemreg_k, stat);
    sys_stat_parm_vstr (name, stat);
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
  sym_p: code_symbol_p_t;              {pointer to new symbol}

begin
  adrsp_p := nil;                      {init to address space not created}

  code_sym_new (                       {create the new memory symbol}
    code,                              {CODE library use state}
    name,                              {name of symbol to create}
    code.memsym_p^,                    {symbol table to add symbol to}
    sym_p,                             {returned pointer to new symbol}
    stat);
  if sys_error(stat) then return;

  sym_p^.symtype := code_symtype_adrsp_k; {new symbol is address space}
  util_mem_grab (                      {alloc mem for adr space descriptor}
    sizeof(adrsp_p^), code.memsym_p^.mem_p^, false, adrsp_p);
  util_mem_grab_err_bomb (adrsp_p, sizeof(adrsp_p^));
  sym_p^.adrsp_p := adrsp_p;           {point symbol to new adr space descriptor}

  adrsp_p^.sym_p := sym_p;
  adrsp_p^.region_p := nil;
  adrsp_p^.bitsadr := 0;
  adrsp_p^.bitsdat := 0;
  adrsp_p^.accs := [];
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
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of adr space to find}
  out     adrsp_p: code_adrspace_p_t;  {returned pointer to the adr space, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  sym_p: code_symbol_p_t;              {pointer to address space symbol}

begin
  sys_error_none (stat);               {init to no error}
  adrsp_p := nil;                      {init to adress space not found}

  code_sym_lookup (                    {look up name in memories symbol table}
    code,                              {CODE library use state}
    name,                              {name of symbol to look up}
    code.memsym_p^,                    {symbol table to look in}
    sym_p);                            {returned pointer to symbol, NIL = not found}
  if sym_p = nil then begin            {no such memory symbol ?}
    sys_stat_set (code_subsys_k, code_stat_noadrsp_k, stat);
    sys_stat_parm_vstr (name, stat);
    return;
    end;

  if sym_p^.symtype <> code_symtype_adrsp_k then begin {symbol is not adr space ?}
    sys_stat_set (code_subsys_k, code_stat_notadrsp_k, stat);
    sys_stat_parm_vstr (name, stat);
    return;
    end;

  adrsp_p := sym_p^.adrsp_p            {return pointer to the address space}
  end;
{
********************************************************************************
*
*   Subroutine CODE_ADRREG_NEW (CODE, NAME, ADRNAME, ADRREG_P, STAT)
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
  sym_p: code_symbol_p_t;              {pointer to new symbol data in symbol table}
  adr_p: code_adrspace_p_t;            {pointer to parent address space}

begin
  adrreg_p := nil;                     {init to new adr region not created}

  code_sym_new (                       {create the new memory symbol}
    code,                              {CODE library use state}
    name,                              {name of symbol to create}
    code.memsym_p^,                    {symbol table to add symbol to}
    sym_p,                             {returned pointer to new symbol}
    stat);
  if sys_error(stat) then return;

  util_mem_grab (                      {alloc mem for address space descriptor}
    sizeof(adrreg_p^), code.memsym_p^.mem_p^, false, adrreg_p);
  util_mem_grab_err_bomb (adrreg_p, sizeof(adrreg_p^));

  sym_p^.symtype := code_symtype_adrreg_k; {new symbol is for a address region}
  sym_p^.adrreg_p := adrreg_p;

  adrreg_p^.next_p := nil;
  adrreg_p^.sym_p := sym_p;
  adrreg_p^.space_p := nil;
  adrreg_p^.adrst := 0;
  adrreg_p^.adren := 0;
  adrreg_p^.memreg_p := nil;
  adrreg_p^.accs := [];
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
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of adr region to find}
  out     adrreg_p: code_adrregion_p_t; {returned pointer to the adr region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  sym_p: code_symbol_p_t;              {pointer to symbol data in symbol table}

begin
  sys_error_none (stat);               {init to no error}
  adrreg_p := nil;                     {init to not returning with memory region}

  code_sym_lookup (                    {look up name in memories symbol table}
    code,                              {CODE library use state}
    name,                              {name of symbol to look up}
    code.memsym_p^,                    {symbol table to look in}
    sym_p);                            {returned pointer to symbol, NIL = not found}
  if sym_p = nil then begin
    sys_stat_set (code_subsys_k, code_stat_noadrreg_k, stat);
    sys_stat_parm_vstr (name, stat);
    return;
    end;

  if sym_p^.symtype <> code_symtype_adrreg_k then begin {symbol not a mem region ?}
    sys_stat_set (code_subsys_k, code_stat_notadrreg_k, stat);
    sys_stat_parm_vstr (name, stat);
    return;
    end;

  adrreg_p := sym_p^.adrreg_p;         {return pointer to the memory region}
  end;
{
********************************************************************************
*
*   Local function MEMREG_LIST_ADD (CODE, LIST_P, MEMREG)
*
*   Added the memory region MEMREG to the list of memory regions pointed to by
*   LIST_P.  LIST_P may be NIL initially.  It is always returned pointing to the
*   updated complete list.  The function returns TRUE if a new entry was added
*   to the list, and FALSE if MEMREG was already in the list.  In the latter
*   case, nothing else is done.
}
function memreg_list_add (             {add entry to memory regions list}
  in out  code: code_t;                {CODE library use state}
  in out  list_p: code_memreg_ent_p_t; {pointer to list, may be NIL, updated}
  in var  memreg: code_memregion_t)    {memory region to add to the list}
  :boolean;                            {added, not duplicate}
  val_param; internal;

var
  ent_p: code_memreg_ent_p_t;          {pointer to list entry}
  last_p: code_memreg_ent_p_t;         {pointer to last list entry}

begin
  memreg_list_add := true;             {init to new entry added}
{
*   Check for duplicate, find last list entry.
}
  ent_p := list_p;                     {init to first entry}
  while ent_p <> nil do begin          {scan the list}
    if ent_p^.region_p = addr(memreg) then begin {mem region already in list ?}
      memreg_list_add := false;
      return;
      end;
    last_p := ent_p;                   {update pointer to last list entry}
    ent_p := ent_p^.next_p;            {to next list entry}
    end;                               {back to check this new list entry}
{
*   MEMREG is not already in the list.  LAST_P is pointing to the last list
*   entry unless the list is empty.  An empty list is indicated by LIST_P being
*   NIL.
}
  code_alloc_global (code, sizeof(ent_p), ent_p); {create new list entry}
  ent_p^.next_p := nil;                {fill in the new list entry}
  ent_p^.region_p := addr(memreg);

  if list_p = nil
    then begin                         {no existing list}
      list_p := ent_p;                 {pass back pointer to this only entry}
      end
    else begin                         {adding to existing list}
      last_p^.next_p := ent_p;         {link new entry to end of list}
      end
    ;
  end;
{
********************************************************************************
*
*   Subroutine CODE_ADRREG_MEMREG_ADD (CODE, ADRREG, MEMREG, STAT)
*
*   Add a memory region to an address region descriptor.  ADRREG is the address
*   region descriptor being added to.  MEMREG is an additional memory region
*   that the address region can map to.
}
procedure code_adrreg_memreg_add (     {add mapped-to mem region to address region}
  in out  code: code_t;                {CODE library use state}
  in out  adrreg: code_adrregion_t;    {address region to add mapping to}
  in var  memreg: code_memregion_t;    {memory region being added}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not memreg_list_add (code, adrreg.memreg_p, memreg) then begin {add to list}
    sys_stat_set (code_subsys_k, code_stat_mreg_inlist_k, stat);
    sys_stat_parm_vstr (adrreg.sym_p^.name_p^, stat);
    sys_stat_parm_vstr (memreg.sym_p^.name_p^, stat);
    return;
    end;

  sys_error_none (stat);               {indicate success}
  end;
{
********************************************************************************
*
*   Local subroutine SHOW_ATTR (ATTR, INDENT)
*
*   Show the memory attributes specified by ATTR.
}
procedure show_attr (                  {show attributes}
  in      attr: code_memattr_t;        {attributes to show}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param; internal;

begin
  string_nblanks (indent);
  write ('Attributes:');
  if code_memattr_nv_k in attr then write (' NON-VOLATILE');
  writeln;
  end;
{
********************************************************************************
*
*   Local subroutine SHOW_ACCS (ACCS, INDENT)
*
*   Show the accesses specifies by ACCS.
}
procedure show_accs (                  {show access}
  in      accs: code_memaccs_t;        {accesses to show}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param; internal;

begin
  string_nblanks (indent);
  write ('Access:');
  if code_memaccs_rd_k in accs then write (' READ');
  if code_memaccs_wr_k in accs then write (' WRITE');
  if code_memaccs_ex_k in accs then write (' EXECUTE');
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
  in      sym: code_symbol_t;          {mem/adr symbol to show data of}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param;

var
  mreg_p: code_memregion_p_t;          {pointer to memory region}
  areg_p: code_adrregion_p_t;          {pointer to address region}
  mreg_ent_p: code_memreg_ent_p_t;     {pointer to memory region list entry}
  len: sys_int_conv32_t;               {memory length}
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
      show_accs (sym.memory_p^.accs, indent+2);
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
      len := sym.memreg_p^.adren - sym.memreg_p^.adrst + 1;
      string_f_int32h (tk, len);
      writeln (tk.str:tk.len, 'h (', len, ')');

      show_accs (sym.memreg_p^.accs, indent+2);
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

      show_accs (sym.adrsp_p^.accs, indent+2);
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
      len := sym.memreg_p^.adren - sym.memreg_p^.adrst + 1;
      string_f_int32h (tk, len);
      writeln (tk.str:tk.len, 'h (', len, ')');

      string_nblanks (indent+2);
      write ('Mapped to mem regions:');
      mreg_ent_p := sym.adrreg_p^.memreg_p;
      while mreg_ent_p <> nil do begin
        write (' ', mreg_ent_p^.region_p^.sym_p^.name_p^.str:mreg_ent_p^.region_p^.sym_p^.name_p^.len);
        mreg_ent_p := mreg_ent_p^.next_p;
        end;
      writeln;

      show_accs (sym.adrreg_p^.accs, indent+2);
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
  sym_p: code_symbol_p_t;              {pointer to symbol data in symbol table}

begin
  string_hash_pos_first (              {to first symbol table entry}
    code.memsym_p^.hash, pos, found);
  while found do begin                 {loop over all symbols in symbol table}
    string_hash_ent_atpos (pos, name_p, sym_p); {get data for this table entry}
    code_memsym_show (sym_p^, indent); {show this symbol}
    string_hash_pos_next (pos, found); {to next symbol in symbol table}
    end;
  end;
