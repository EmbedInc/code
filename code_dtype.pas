{   Data types handling.
}
module code_dtype;
define code_dtype_init;
define code_dtype_resolve;
define code_dtype_new_intable;
define code_dtype_new_inscope;
define code_dtype_new_sym;
define code_dtype_copy;
define code_dtype_sym_new_intable;
define code_dtype_sym_new_inscope;
define code_dtype_sym_new;
define code_dtype_sym_set;
define code_dtype_sym_resolve;
define code_dtype_find;
define code_dtype_int_gnam;
define code_dtype_int_find;
define code_dtype_show;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_INIT (DTYPE)
*
*   Initialize the data type descriptor DTYPE to default or benign values to the
*   extent possible.  The data type of DTYPE will be UNDEFINED.
}
procedure code_dtype_init (            {initialize a data type descriptor}
  in out  dtype: code_dtype_t);        {descriptor to initialize to default or benign}
  val_param;

begin
  dtype.symbol_p := nil;
  dtype.comm_p := nil;
  dtype.bits_min := 0;
  dtype.mem_p := nil;
  dtype.flags := [];
  dtype.typ := code_typid_undef_k;
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_RESOLVE (DTYPE, FINAL_P)
*
*   Resolve the data type DTYPE to a final resolved type, not a copy.  FINAL_P
*   is returned pointing to the final type.  FINAL_P will point to DTYPE when
*   DTYPE is not a COPY data type.
}
procedure code_dtype_resolve (         {resolve absolute data type}
  var in  dtype: code_dtype_t;         {dtype to resolve final type of}
  out     final_p: code_dtype_p_t);    {returned pointer to final (not copy) dtype}
  val_param;

begin
  if dtype.typ = code_typid_copy_k
    then begin                         {DTYPE is a copy}
      final_p := dtype.copy_dtype_p;   {return pointer to base data type}
      end
    else begin                         {DTYPE is already a base data type, not copy}
      final_p := addr(dtype);          {return pointer to DTYPE directly}
      end
    ;
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_NEW_INTABLE (CODE, SYMTAB, DTYPE_P)
*
*   Allocate and initialize a new data type descriptor.  The new descriptor will
*   be allocated under the memory context of the symbol table SYMTAB.
}
procedure code_dtype_new_intable (     {create and init new dtype in specific sym table}
  in out  code: code_t;                {CODE library use state}
  in out  symtab: code_symtab_t;       {symbol table to add the data type to}
  out     dtype_p: code_dtype_p_t);    {to newly created data type, initialized}
  val_param;

begin
  code_alloc_symtab (                  {alloc mem for the new dtype descriptor}
    symtab, sizeof(dtype_p^), dtype_p);

  code_dtype_init (dtype_p^);          {init to default or benign values}
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_NEW_INSCOPE (CODE, SCOPE, DTYPE_P)
*
*   Allocate and initialize a new data type descriptor.  The new descriptor will
*   be allocated under the context of the data types symbol table of the scope
*   SCOPE.
}
procedure code_dtype_new_inscope (     {create and init new dtype in specific scope}
  in out  code: code_t;                {CODE library use state}
  in out  scope: code_scope_t;         {scope to create the data type within}
  out     dtype_p: code_dtype_p_t);    {to newly created data type, initialized}
  val_param;

var
  symtab_p: code_symtab_p_t;           {to symbol table to alloc mem under}

begin
  symtab_p := code_symtab_symtype (    {get pointer to symbol table to alloc dtype in}
    code, scope, code_symtype_dtype_k);
  code_dtype_new_intable (             {alloc and init the new data type descriptor}
    code, symtab_p^, dtype_p);
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_NEW_SYM (CODE, SYM)
*
*   Create a new data type descriptor and link the symbol SYM to it.  SYM must
*   already be a data type, but its data type must not be set yet.
}
procedure code_dtype_new_sym (         {create new data type, connect to existing symbol}
  in out  code: code_t;                {CODE library use state}
  in out  sym: code_symbol_t);         {sym to connect data type to, must not already be set}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  dtype_p: code_dtype_p_t;             {to new data type descriptor}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  if sym.symtype <> code_symtype_dtype_k then begin {symbol not a data type ?}
    sys_msg_parm_vstr (msg_parm[1], sym.name_p^);
    code_err_atline (code, '', 'err_sym_not_dtype', msg_parm, 1);
    end;
  if sym.dtype_dtype_p <> nil then begin {symbol data type alread set ?}
    sys_msg_parm_vstr (msg_parm[1], sym.name_p^);
    code_err_atline (code, '', 'err_sym_dtype_set', msg_parm, 1);
    end;

  code_dtype_new_intable (code, sym.symtab_p^, dtype_p); {alloc and init new dtype}
  dtype_p^.symbol_p := addr(sym);      {point data type back to its symbol}
  sym.dtype_dtype_p := dtype_p;        {link symbol to new data type}
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_COPY (ORIG, COPY)
*
*   Fill in the data type COPY to be a COPY data type pointing to ORIG.
}
procedure code_dtype_copy (            {make COPY data type}
  var in  orig: code_dtype_t;          {original data type to copy}
  out     copy: code_dtype_t);         {will be filled in as copy of ORIG}
  val_param;

begin
  code_dtype_init (copy);              {intialize the copy data type}

  copy.bits_min := orig.bits_min;
  copy.mem_p := orig.mem_p;
  copy.flags := orig.flags;
  copy.typ := code_typid_copy_k;       {this will be a COPY data type}
  copy.copy_symbol_p := orig.symbol_p; {to copied data type symbol}
  code_dtype_resolve (orig, copy.copy_dtype_p); {point to final real data type}
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_SYM_NEW_INTABLE (CODE, NAME, TABLE, SYM_P)
*
*   Create a new data type symbol in the symbol table TABLE.  SYM_P is returned
*   pointing to the new data type symbol.  It is an error if NAME already exists
*   in the symbol table.
*
*   The symbol is set as a data type, with the pointer to the data type
*   descriptor not set yet.  Comments are not attached to the symbol.
}
procedure code_dtype_sym_new_intable ( {new dtype sym in specific sym table, err if exists}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of data type to create}
  in out  symtab: code_symtab_t;       {symbol table to add the data type to}
  out     sym_p: code_symbol_p_t);     {to new data type symbol, NIL on error}
  val_param;

var
  stat: sys_err_t;                     {completion status}

begin
  code_sym_new (                       {create the new symbol}
    code,                              {CODE library use state}
    name,                              {name of the symbol to create}
    symtab,                            {symbol table to create the symbol in}
    sym_p,                             {returned pointer to the new symbol}
    stat);
  code_err_atline_check (code, stat, '', '', nil, 0);

  sym_p^.symtype := code_symtype_dtype_k; {new symbol is a data type}
  sym_p^.dtype_dtype_p := nil;         {pointer to data type not filled in yet}
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_SYM_NEW_INSCOPE (CODE, NAME, SCOPE, SYM_P)
*
*   Create a new data type symbol in the scope SCOPE.  SYM_P is returned
*   pointing to the new data type symbol.  It is an error if NAME already exists
*   in the data types symbol table of the scope.
*
*   The symbol is set as a data type, with the pointer to the data type
*   descriptor not set yet.  Comments are not attached to the symbol.
}
procedure code_dtype_sym_new_inscope ( {new dtype sym in specific scope, err if exists}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of data type to create}
  in out  scope: code_scope_t;         {scope to create the data type within}
  out     sym_p: code_symbol_p_t);     {to new data type symbol, NIL on error}
  val_param;

var
  symtab_p: code_symtab_p_t;           {to dtype symbol table in the scope}

begin
  symtab_p := code_symtab_symtype (    {get pointer to dtype symbol table}
    code, scope, code_symtype_dtype_k);

  code_dtype_sym_new_intable (         {add data type symbol to the symbol table}
    code, name, symtab_p^, sym_p);
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_SYM_NEW (CODE, NAME, SYM_P)
*
*   Create a new data type symbol in the current scope.  SYM_P is returned
*   pointing to the new data type symbol.  It is an error if NAME already exists
*   in the data types symbol table of the current scope.
*
*   The symbol is set as a data type, with the pointer to the data type
*   descriptor not set yet.  Comments are not attached to the symbol.
}
procedure code_dtype_sym_new (         {new data type symbol in curr scope}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of data type to create}
  out     sym_p: code_symbol_p_t);     {to new data type symbol, NIL on error}
  val_param;

begin
  code_dtype_sym_new_inscope (         {create data type symbol in specific scope}
    code,                              {CODE library use state}
    name,                              {name of data type to create}
    code.scope_p^,                     {scope to create data type within}
    sym_p);                            {returned pointer to new data type symbol}
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_SYM_SET (CODE, SYM, TEMPLATE)
*
*   Set the data type reference of the data type symbol SYM.  Nothing is done if
*   the symbol SYM is not a data type, or its pointer to the data type
*   descriptor has already been filled in.  The data type is set to be the same
*   as the data type described by TEMPLATE.
}
procedure code_dtype_sym_set (         {set dtype reference in symbol}
  in out  code: code_t;                {CODE library use state}
  in out  sym: code_symbol_t;          {symbol to set dtype in, err if already set}
  in      template: code_dtype_t);     {template data type}
  val_param;

var
  dtype_p: code_dtype_p_t;             {to base data type descriptor}
  copy: boolean;                       {make copy to base dtype, not use directly}

begin
  if sym.symtype <> code_symtype_dtype_k {symbol is not a data type ?}
    then return;
  if sym.dtype_dtype_p <> nil          {data type already set for this symbol ?}
    then return;

  copy := false;                       {init to link to the base data type directly}
{
*   Check for data types that require special handling.  For these data types,
*   we might not just make a copy of the template and link the symbol to it.
}
  case template.typ of                 {which base data type is it ?}
    {
    *   Integer.  Reuse or create the base data type in the root scope.  This
    *   guarantees that all integers of the same type are ultimately seen as the
    *   same.
    }
code_typid_int_k: begin                {integer}
      code_dtype_int_find (code, template, dtype_p); {find or make base data type}
      copy := true;                    {point sym to copy of base data type}
      end;
    {
    *   Data types that require no special handling.  We create a new data type
    *   descriptor like the template, and link the symbol to it.
    }
otherwise
    code_alloc_symtab (                {allocate memory for data type descriptor}
      sym.symtab_p^, sizeof(dtype_p^), dtype_p);
    dtype_p^ := template;              {make permanent copy of the template descriptor}
    end;
{
*   DTYPE_P is pointing to a permanent data type descriptor matching TEMPLATE.
*   Now set the symbol pointing to this descriptor.  When COPY is TRUE, a data
*   type copy of DTYPE_P^ is created, and the symbol pointed to that instead of
*   pointing directly to DTYPE_P^.
}
  if copy
    then begin                         {point symbol to data type copy}
      code_dtype_new_intable (         {create new dtype in same symtable as SYM}
        code, sym.symtab_p^, sym.dtype_dtype_p);
      code_dtype_copy (                {fill in new data as copy of DTYPE_P^}
        dtype_p^,                      {the data type to copy}
        sym.dtype_dtype_p^);           {dtype to fill in as a copy}
      end
    else begin                         {point to the base data type directly}
      sym.dtype_dtype_p := dtype_p;
      end
    ;
  sym.dtype_dtype_p^.symbol_p := addr(sym); {link new dtype to its symbol}
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_SYM_RESOLVE (CODE, SYM, DTYPE_P)
*
*   Return DTYPE_P pointing to the actual real data type referenced by the data
*   type symbol SYM.  DTYPE_P is guaranteed not to be pointing to a copy data
*   type.  Note that the data type descriptor pointed to by DTYPE_P might not
*   point back to the symbol SYM.
*
*   DTYPE_P is returned NIL when SYM is not a data type symbol, or its data type
*   is not set.
}
procedure code_dtype_sym_resolve (     {resolve dtype sym to final dtype descriptor}
  in out  code: code_t;                {CODE library use state}
  in      sym: code_symbol_t;          {data type symbol to resolve final type of}
  out     dtype_p: code_dtype_p_t);    {to final real (not copy) data type, NIL on not set}
  val_param;

begin
  dtype_p := nil;                      {init to not returning with a data type}
  if sym.symtype <> code_symtype_dtype_k {symbol is not a data type ?}
    then return;
  if sym.dtype_dtype_p = nil           {data type of symbol not resolved ?}
    then return;

  code_dtype_resolve (sym.dtype_dtype_p^, dtype_p); {resolve to real data type}
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_FIND (CODE, NAME, SYM_P, DTYPE_P)
*
*   Find the data type of name NAME within the current hierarch of scopes.
*   SYM_P is returned pointing to the data type symbol, and DTYPE_P to the fully
*   resolved data type.
*
*   When no data type symbol of name NAME is found within the current hierarchy
*   of scopes, then both SYM_P and DTYPE_P are returned NIL.
*
*   DTYPE_P is also returned NIL when the data type is found (SYM_P not NIL),
*   but its data type has not been set.
}
procedure code_dtype_find (            {find data type in curr scopes hierarchy}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of the data type}
  out     sym_p: code_symbol_p_t;      {to dtype symbol, NIL on not found}
  out     dtype_p: code_dtype_p_t);    {to final resolved dtype descriptor}
  val_param;

begin
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_INT_GNAM (CODE, DTYPE, NAME)
*
*   Make the generic name for the integer data type DTYPE.  The empty string is
*   returned when DTYPE is not an integer data type.
*
*   The generic integer data type names have the format:
*
*     int nn [x] [u or s]  [_min] _t
*
*   NN is the minimum required number of bits.  X indicates the integer must
*   behave as if it had exactly NN bits, not more even if more are stored.  U
*   and S indicate signed and unsigned.  The optional _MIN indicates that the
*   minimum possible number of bits should be used.
*
*   For example "int8u_t" is an unsigned integer of at least 8 bits, but more
*   can be used if that uses the target hardware more efficiently.
}
procedure code_dtype_int_gnam (        {make generic name of integer data type}
  in out  code: code_t;                {CODE library use state}
  in      dtype: code_dtype_t;         {integer data type to make generic name of}
  in out  name: univ string_var_arg_t); {returned generic name}
  val_param;

begin
  name.len := 0;                       {init to not returning name}
  if dtype.typ <> code_typid_int_k     {not integer data type ?}
    then return;

  string_appendn (name, 'int', 3);     {fixed part of name}

  string_append_intu (name, dtype.bits_min, 0); {min required number of bits}

  if dtype.int_exactbits then begin
    string_append1 (name, 'x');        {as if BITS_MIN exactly}
    end;

  if dtype.int_sign
    then string_append1 (name, 's')    {signed}
    else string_append1 (name, 'u');   {unsigned}

  if code_typflag_pack_k in dtype.flags then begin
    string_appendn (name, '_min', 4);  {use minimum size}
    end;

  string_appendn (name, '_t', 2);      {fixed suffix}
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_INT_FIND (CODE, TEMPLATE, DTYPE_P)
*
*   Find the single base integer data type descriptor matching the data type
*   TEMPLATE.  If no such base integer data type exists, then it is created.
*   Either way, DTYPE_P is returned pointing to this base integer data type.
*
*   DTYPE_P is returned NIL when TEMPLATE is not an integer data type.
*
*   A single base copy of all integer data types is kept in the root scope.
*   This allows recognizing equivalent integer data types and treating them as
*   the same.
*
*   The integer data types in the root scope have specific "decorated" names.
*   See the header comment of CODE_DTYPE_INT_GNAM (above) for the name format.
}
procedure code_dtype_int_find (        {find or make base integer data type}
  in out  code: code_t;                {CODE library use state}
  in      template: code_dtype_t;      {template integer data type, must not be copy}
  out     dtype_p: code_dtype_p_t);    {returned pointer to INT data type in root scope}
  val_param;

var
  name: string_var32_t;                {decorated name of base integer data type}
  sym_p: code_symbol_p_t;              {to base integer data type symbol}

begin
  name.max := size_char(name.str);     {init local var string}
  dtype_p := nil;                      {init to not returning with data type}
  if template.typ <> code_typid_int_k  {not integer data type ?}
    then return;

  code_dtype_int_gnam (code, template, name); {make name of this integer data type}

  code_sym_lookup (code, name, code.dtcomm_p^, sym_p); {try to find existing symbol}

  if sym_p = nil then begin            {this base data type doesn't already exist ?}
    code_dtype_sym_new_intable (       {create new data type symbol}
      code, name, code.dtcomm_p^, sym_p);
    code_dtype_new_sym (code, sym_p^); {create new data type, link to symbol}
    sym_p^.dtype_dtype_p^ := template; {fill in the integer data type descriptor}
    sym_p^.dtype_dtype_p^.symbol_p := sym_p; {point new dtype back to its symbol}
    end;

  dtype_p := sym_p^.dtype_dtype_p;     {return pointer to the data type descriptor}
  end;
{
********************************************************************************
*
*   Subroutine CODE_DTYPE_SHOW (CODE, DTYPE, LEV, SHOW)
*
*   Write a description of the data type DTYPE to standard output.  LEV is the
*   nesting level the information is being shown at, and SHOW is a set of flags
*   that enable showing of additional information.  See the header comments of
*   CODE_SYM_SHOW for details of LEV and SHOW.
*
*   The basic data type description is written at the current output position.
*   LEV only matters when additional lines are written.
}
procedure code_dtype_show (            {show data type description to user}
  in out  code: code_t;                {CODE library use state}
  var in  dtype: code_dtype_t;         {data type to show}
  in      lev: sys_int_machine_t;      {nesting level data being shown at, 0 = top}
  in      show: code_symshow_t);       {flags enabling optional information to show}
  val_param;

var
  sp: boolean;                         {current position is after a space}
  base_p: code_dtype_p_t;              {to base data type definition, not copy}
  str: string_var256_t;                {scratch string}
{
****************************************
*
*   Local subroutine SPACE
*   This routine is local to CODE_DTYPE_SHOW.
*
*   Write a space unless there is already a space before the current writing
*   position.
}
procedure space;
  internal;

begin
  if not sp then begin
    write (' ');
    sp := true;
    end;
  end;
{
****************************************
*
*   Local subroutine SHOW_BITS
*   This routine is local to CODE_DTYPE_SHOW.
*
*   Show the number of bits the data type uses or requires.
}
procedure show_bits;
  internal;

begin
  space;
  write (dtype.bits_min, ' bits');
  if code_typflag_pack_k in dtype.flags then begin
    writeln ('min');
    end;
  sp := false;
  end;
{
****************************************
*
*   Local subroutine SHOW_TYPE (ID)
*   This routine is local to CODE_DTYPE_SHOW.
*
*   Show the basic data type indicated by ID.
}
procedure show_type (                  {show basic data type}
  in      id: code_typid_k_t);         {ID of the type to show}
  val_param; internal;

begin
  space;
  case id of                           {which type is it ?}
code_typid_undef_k: write ('UNDEF');
code_typid_undefp_k: write ('UNDEF PTR');
code_typid_copy_k: write ('COPY');
code_typid_int_k: write ('INT');
code_typid_enum_k: write ('ENUM');
code_typid_float_k: write ('FLOAT');
code_typid_bool_k: write ('BOOL');
code_typid_char_k: write ('CHAR');
code_typid_agg_k: write ('AGG');
code_typid_array_k: write ('ARRAY');
code_typid_set_k: write ('SET');
code_typid_range_k: write ('RANGE');
code_typid_proc_k: write ('PROC');
code_typid_pnt_k: write ('PNT');
code_typid_vstr_k: write ('VSTR');
code_typid_flxstr_k: write ('FLXSTR');
otherwise
    write ('typid ', ord(id));
    end;
  sp := false;
  end;
{
****************************************
*
*   Start of main routine.
}
begin
  str.max := size_char(str.str);       {init local var string}
  sp := true;                          {init to no leading space needed}
  code_dtype_resolve (dtype, base_p);  {resolve to final non-copy data type}
  if base_p <> nil then begin
    show_type (base_p^.typ);           {show name of base data type}
    end;

  case dtype.typ of                    {which basic type is the orginal dtype ?}
code_typid_undef_k: begin
      end;
code_typid_undefp_k: begin
      end;
code_typid_copy_k: begin
      space;
      write ('COPY');
      if
          (base_p <> nil) and then
          (base_p^.symbol_p <> nil)
          then begin
        code_symname_abs (code, base_p^.symbol_p^, str); {make full name string}
        write (' of ', str.str:str.len);
        end;
      end;
code_typid_int_k: begin
      show_bits;
      if dtype.int_exactbits then write (' exact');
      if dtype.int_sign then write (' signed');
      end;
code_typid_enum_k: begin
      show_bits;
      end;
code_typid_float_k: begin
      show_bits;
      end;
code_typid_bool_k: begin
      show_bits;
      end;
code_typid_char_k: begin
      show_bits;
      end;
code_typid_agg_k: begin
      show_bits;
      end;
code_typid_array_k: begin
      end;
code_typid_set_k: begin
      show_bits;
      end;
code_typid_range_k: begin
      show_bits;
      end;
code_typid_proc_k: begin
      end;
code_typid_pnt_k: begin
      show_bits;
      end;
code_typid_vstr_k: begin
      end;
code_typid_flxstr_k: begin
      end;
    end;                               {end of which data type cases}
  end;
