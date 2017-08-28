#!/usr/bin/env python3
# =======================================================================
#
#  reg_geni.py                                           date: 2017/06/15
#
# $Id$
# $Source$
# =======================================================================
header = '''
/*
// =======================================================================
//
//  Author: Simon Southwell
//
//  Copyright (c) 2017 Simon Southwell
//
//  This file is part of the cpumico32 instruction set simulator.
//
//  This file is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  The code is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this file. If not, see <http://www.gnu.org/licenses/>.
//
// =======================================================================
'''
# The above header definition also serves as the copyright notice for this file

import os
import sys
import xlrd
from enum import Enum

# Define some constants
class state_e(Enum) :
  BASE        = 0
  REG         = 1
  FIELD       = 2

class type_e(Enum) :
  C           = 0
  VERILOG     = 1
  ASM         = 2

DEFINE_LEN    = 50
SHEET_NAME    = 'registers'
VLOG_FNAME    = 'regs.vh'
C_FNAME       = 'regs.h'
ASM_FNAME     = 'regs.s'

AUTOGEN_HDR   = '''//  NB: This file has been automatically generated --- DO NOT EDIT! 
// =======================================================================
*/
'''

DIVIDER       = '/* ----------------------------------------------------------------------- */'

# -----------------------------------------------------------------------
# hex_lead
#
#
#
# -----------------------------------------------------------------------

def hex_lead (value, val_width = 32, vlog = False, rq_hex = True, vlog_int = False) :

  is_hex = False

  # Make sure we have a value as a string
  if not isinstance (value, str) :
    if rq_hex :
      val_str = hex(value)
      # Remove leading '0x', as we may need to expand with leading zeros
      val_str = val_str[2:]
      is_hex = True
    else :
      val_str = str(value)
  else :
    val_str = value
    # Remove any leading '0x'
    if val_str[0:2] == '0x' :
      val_str = val_str[2:]
      is_hex = True

  if vlog :
    # In verilog, and not a hex number, if marked as an integer
    # number spec required
    if not is_hex and vlog_int :
      hstr = ''
    elif is_hex :
      hstr = str(val_width) + '\'h'
    else :
      hstr = str(val_width) + '\'d'
  else :
    if is_hex :
      hstr = '0x'
    else :
      hstr = ''

  # For hex numbers, make sure there are enough leading zeros
  if is_hex and len(val_str) < ((val_width + 3) >> 2) :
    val_str = ('0' * (((val_width + 3) >> 2) - len(val_str))) + val_str

  return hstr + val_str

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

def gen_masks (fp, flst, dpfx, pfx, rname, is_asm) :

  for fname, w, bp in flst :
    # Construct a define string for the bit position
    pstr = dpfx + pfx + '_' + rname + '_' + fname + '_MASK'

    if is_asm :
      pstr += ','

    # Ensure the define string is the minimum width, and pad with spaces
    if len(pstr) < DEFINE_LEN :
      pstr = pstr + ' ' * (DEFINE_LEN - len(pstr))

    # mask value s (2^width -1) << bit position
    mask = ((1 << w) - 1) << bp

    # Output the define string and the formatted mask value
    fp.write (pstr + hex_lead(mask, 32, False, True, False) + '\n')

  fp.write('\n')

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

def gen_vlog_ranges (fp, flst, dpfx, pfx, rname) :

  for fname, w, bp in flst :

    # Construct a define string for the bit position
    pstr = dpfx + pfx + '_' + rname + '_' + fname + '_RNG'

    # Ensure the define string is the minimum width, and pad with spaces
    if len(pstr) < DEFINE_LEN :
      pstr = pstr + ' ' * (DEFINE_LEN - len(pstr))

    rstr = str(bp)
    if w != 1 :
      rstr =  str(bp+w-1) + ':' + rstr

    fp.write (pstr + rstr + '\n')

  fp.write('\n')

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

def gen_c_macros (fp, flst, dpfx, pfx, rname) :

  for fname, w, bp in flst :

    rootstr = pfx + '_' + rname + '_' + fname

    # Construct a define string for the bit position
    pstr = dpfx + rootstr + '_VAL(_rval)'

    # Ensure the define string is the minimum width, and pad with spaces
    if len(pstr) < DEFINE_LEN :
      pstr = pstr + ' ' * (DEFINE_LEN - len(pstr))

    mstr =  '(((_rval) & ' + rootstr + '_MASK) >> ' + rootstr + '_BIT)'

    fp.write(pstr + mstr + '\n')

  fp.write('\n')

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

def gen_defs(gen_type, reg_sheet, fp = sys.stdout) :

  fp.write(header + AUTOGEN_HDR + '\n')

  state = state_e.BASE

  is_vlog = gen_type == type_e.VERILOG
  is_asm  = gen_type == type_e.ASM

  if gen_type == type_e.VERILOG :
    define_prefix = '`define '
  elif gen_type == type_e.C :
    define_prefix = '#define '
  else :
    define_prefix = '    .equ '

  field_names = reg_sheet.row(0)
  fld_dict = {}
  fidx = 0

  for fld in field_names :
    fld_dict.update({fld.value : fidx})
    fidx += 1

  row_idx        = 1
  inst_idx       = 0
  prefix         = ''
  reg_name       = ''
  bit_pos        = 0
  base_name_dict = {}

  terminate = False

  # Scan through rows of the register sheet until no more rows,
  # or reached terminator
  while row_idx < reg_sheet.nrows  and not terminate:

    row = reg_sheet.row(row_idx)
    row_idx += 1

    if row[fld_dict['name']].value == '##########' :
      terminate = True

      if not field_list == []:

        fp.write('\n')
        if is_vlog :
          gen_vlog_ranges(fp, field_list, define_prefix, prefix, reg_name)
        else :
          gen_masks(fp, field_list, define_prefix, prefix, reg_name, is_asm)
          if not is_asm :
            gen_c_macros(fp, field_list, define_prefix, prefix, reg_name)

    elif state == state_e.BASE  :

      # Skip empty rows whilst looking for a base definition
      if row[fld_dict['base']].ctype != xlrd.XL_CELL_EMPTY :

          fp.write(DIVIDER + '\n\n')

          # Determine if this has the 'unique' setting (i.e. suppress instance indexing)
          if row[fld_dict['unique']].ctype != xlrd.XL_CELL_EMPTY:
            unique = True
          else :
            unique = False

          # Get value of base address, and set next state for a register
          # (must be at least 1), unless register field is '*', when this
          # is another instantiation, and a new base address will follow
          prefix = row[fld_dict['name']].value
          if row[fld_dict['register']].value == '*' :
            state = state_e.BASE
          else :
            state = state_e.REG

          if not unique :

            # If we haven't seen this prefix before, set the instance index to 0
            if prefix not in base_name_dict :
              inst_idx = 0
            # If we have seen this prefix before, fetch the instance count
            # from the dictionary and increment it
            else :
              inst_idx = base_name_dict[prefix] + 1

            # Add or update a dictionary entry for this prefix with the
            # instance count
            base_name_dict.update ({prefix : inst_idx})

          # Construct the print string for the base address define
          if not unique :
            pstr = define_prefix + prefix + str(inst_idx) + '_BASE_ADDR'
          else :
            pstr = define_prefix + prefix + '_BASE_ADDR'

          # In assembler, need a comma after name
          if is_asm :
            pstr = pstr + ','

          # Ensure the length of the string is DEFINE_LEN
          if len(pstr) < DEFINE_LEN :
            pstr = pstr + ' ' * (DEFINE_LEN - len(pstr))

          # Print out the define string with the value
          fp.write (pstr + hex_lead(row[fld_dict['base']].value, 32, is_vlog) + '\n\n')

    elif state == state_e.REG :

      # If base name cell not empty, go back to BASE state, and
      # decrement index to reprocess this row.
      if row[fld_dict['base']].ctype != xlrd.XL_CELL_EMPTY :
        state = state_e.BASE
        row_idx -= 1
        fp.write('\n')

      # Skip empty register cells whilst in this state
      elif row[fld_dict['register']].ctype != xlrd.XL_CELL_EMPTY :

        reg_name = row[fld_dict['register']].value

        # Construct a print srting defining the register, and make sure
        # it's DEFINE_LEN long
        pstr = define_prefix + prefix + '_' + reg_name + '_REG'

        # In assembler, need a comma after name
        if is_asm :
          pstr = pstr + ','

        if len(pstr) < DEFINE_LEN :
            pstr = pstr + ' ' * (DEFINE_LEN - len(pstr))

        # Print the define string and the value
        fp.write (pstr + hex_lead(row[fld_dict['offset']].value, 8, is_vlog) + '\n')

        # If the width cell is not empty, then no fields for this register
        if row[fld_dict['width']].ctype != xlrd.XL_CELL_EMPTY :
          state = state_e.REG
          #fp.write('\n')

        # If the width cell is empty, then at least one field must be defined
        # so go to FIELD state. Clear the bit position count.
        else :
          state   = state_e.FIELD
          bit_pos = 0
          field_list = []
          fp.write('\n')

    elif state == state_e.FIELD :

      # If base name cell not empty, go back to BASE state, and
      # decrement index to reprocess this row.
      if row[fld_dict['base']].ctype != xlrd.XL_CELL_EMPTY :
        state = state_e.BASE
        row_idx -= 1
        fp.write('\n')
        if is_vlog :
          gen_vlog_ranges(fp, field_list, define_prefix, prefix, reg_name)
        else :
          gen_masks(fp, field_list, define_prefix, prefix, reg_name, is_asm)
          if not is_asm :
            gen_c_macros(fp, field_list, define_prefix, prefix, reg_name)

      # If register name cell not empty, go back to REG state, and
      # decrement index to reprocess this row
      elif row[fld_dict['register']].ctype != xlrd.XL_CELL_EMPTY :
        state = state_e.REG
        row_idx -= 1
        fp.write('\n')
        if is_vlog :
          gen_vlog_ranges(fp, field_list, define_prefix, prefix, reg_name)
        else :
          gen_masks(fp, field_list, define_prefix, prefix, reg_name, is_asm)
          if not is_asm :
            gen_c_macros(fp, field_list, define_prefix, prefix, reg_name)

      else :
        # Get the field name and the width value
        field_name = row[fld_dict['field']].value
        width      = row[fld_dict['width']].value

        field_list.append((field_name, int(width), bit_pos))

        # Construct a define string for the bit position
        pstr = define_prefix + prefix + '_' + reg_name + '_' + field_name + '_BIT'

        # In assembler, need a comma after name
        if is_asm :
          pstr = pstr + ','

        # Ensure the define string is the minimum width, and pad with spaces
        if len(pstr) < DEFINE_LEN :
          pstr = pstr + ' ' * (DEFINE_LEN - len(pstr))

        # Output the define string and the formatted bit position value
        fp.write (pstr + hex_lead(bit_pos, 5, is_vlog, False, True) + '\n')

        # Add the width of the field to the bit position count
        bit_pos += int(width)

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

def do_reg_gen(xlsfname, sheet_name = SHEET_NAME, vlog_fname = VLOG_FNAME, c_fname = C_FNAME, asm_fname = ASM_FNAME) :

  # Open spreadsheet, and get the relevant register sheet
  book      = xlrd.open_workbook(xlsfname)
  sheet     = book.sheet_by_name(sheet_name)

  # Generate C then verilog headers
  for gen_type in [type_e.C, type_e.VERILOG, type_e.ASM] :

    if gen_type == type_e.VERILOG :
      outfp = open(vlog_fname, 'w')
    elif gen_type == type_e.C :
      outfp = open(c_fname,    'w')
    elif gen_type == type_e.ASM :
      outfp = open(asm_fname,  'w')

    gen_defs(gen_type, sheet, outfp)

    outfp.close()

# ###############################################################
# Only run if not imported
#
if __name__ == '__main__' :

  # Get some useful locations
  script_dir  = os.path.dirname(os.path.realpath(sys.argv[0])) + '/'
  run_dir     = os.getcwd()

  # If a filename given on the command line, then use it, otherwise
  # use a default, relative to the location of this script
  if len(sys.argv) > 1 :
    xls_fname = sys.argv[1]
  else :
    xls_fname =  script_dir + '../HDL/registers/registers.xlsx'

  do_reg_gen(xls_fname)

