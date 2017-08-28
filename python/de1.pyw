#!/usr/bin/env python3
# =======================================================================
#                                                                        
#  de1gui.py                                           date: 2017/05/31
#                                                                        
#  Author: Simon Southwell                                               
# 
#  Copyright (c) 2017 Simon Southwell 
#                                                                        
#  This file is part of the cpumico32 instruction set simulator.
#  
#  This file is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  
#  The code is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this file. If not, see <http://www.gnu.org/licenses/>.
#  
#  $Id$
#  $Source$
#                                                                       
# =======================================================================

# Get libraries for interfacing with the OS
import os

# Get everything from Tkinter, as we use quite a lot
from  tkinter      import *

# Override any Tk widgets that have themed versions in ttk,
# and pull in other ttk specific widgets (ie. Separator and Notebook)
#from tkinter.ttk  import *

import socket
import select

# noinspection PyBroadException
class de1gui:

  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Constants of the class (static)
  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  # Define constant mapping between seven segment display supported characters,
  # and the pattern to turn on the LEDs
  seg_dict = {'0' : 0x40, '1' : 0x79, '2' : 0x24, '3'   : 0x30,
              '4' : 0x19, '5' : 0x12, '6' : 0x02, '7'   : 0x78,
              '8' : 0x00, '9' : 0x10, 'A' : 0x08, 'B'   : 0x03,
              'C' : 0x46, 'D' : 0x21, 'E' : 0x06, 'F'   : 0x0e,
              'a' : 0x20, 'b' : 0x03, 'c' : 0x27, 'd'   : 0x21,
              'e' : 0x04, 'f' : 0x0e, 'H' : 0x09, 'h'   : 0x0b,
              'o' : 0x23, 'L' : 0x47, 'p' : 0x0c, 't'   : 0x07,
              'u' : 0x63, 'y' : 0x11, '-' : 0x3f, 'deg' : 0x1c,
              'n' : 0x2b, 'r' : 0x2f, 'P' : 0x0c, 'off' : 0xff,
              ' ' : 0xff, '*' : 0x1c}

  # Define some colours used in the class, mapped to text
  colours = {'red' : '#ffa000', 'blue' : '#00c0ff', 'green' : '#20ff20', 'off' : '#404040'}

  # Define the x and Y coordinates of the seven segment display blocks' origin
  seg7_origin = {'x' : 62, 'y' : 369}

  # Map the origin x and y co-oridinates of the LEDs to tex references
  led_origins = {'ledg0' : (427, 415), 'ledg1' : (407, 415), 'ledg2' : (387, 415), 'ledg3' : (366, 415),
                 'ledg4' : (346, 415), 'ledg5' : (325, 415), 'ledg6' : (305, 415), 'ledg7' : (284, 415),
                 'ledr0' : (254, 415), 'ledr1' : (234, 415), 'ledr2' : (213, 415), 'ledr3' : (193, 415),
                 'ledr4' : (173, 415), 'ledr5' : (151, 415), 'ledr6' : (131, 415), 'ledr7' : (111, 415),
                 'ledr8' : ( 90, 415), 'ledr9' : (69, 415)
                 }

  canvas_dimensions = {'width' : 500, 'height' : 500}

  # The GUIs loop functiion calling delay in milliseconds
  del_gui_loop_delay = 100

  TCP_IP   = '127.0.0.1'
  TCP_PORT = 0xc001
  
  # Reset values of board
  SEG7_reset = '0000'
  LEDR_reset = 0x0000
  LEDG_reset = 0x0000


  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Constructor
  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def __init__(self) :
   
    # Get a Tk object
    self.root = Tk()
    
    # Tk variables for directory locations
    self.scriptdir          = StringVar()
    self.rundir             = StringVar()

    self.loop_count         = 0

    self.tcpOpen            = False

    # ------------------------------------------------------------
    # Set/configure instance objects here
    # ------------------------------------------------------------
    
    self.root.title('de1.py : Copyright (c) 2017 WyvernSemi')
    
    # Configure the font for message boxes (the default is awful)
    self.root.option_add('*Dialog.msg.font', 'Ariel 10')

    # Set some location state
    self.scriptdir.set(os.path.dirname(os.path.realpath(sys.argv[0])))
    self.rundir.set(os.getcwd())


  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # 'private' methods
  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  #
  # Create a polygon object for a seven segment display left segment
  #
  @staticmethod
  def __createLeftPoly (canvas, x, y, on_colour, is_hidden) :
    hdl = canvas.create_polygon ( x+2, y+0, x+0, y+10, x+3, y+9, x+4, y+3, outline = on_colour, fill = on_colour)
    if is_hidden :
      canvas.itemconfig(hdl, state = HIDDEN)

    return hdl

  #
  # Create a polygon object for a seven segment display right segment
  #
  @staticmethod
  def __createRightPoly (canvas, x, y, on_colour, is_hidden) :
    hdl = canvas.create_polygon (x+0, y+8, x+2, y+10, x+4, y+0, x+1, y+1, outline = on_colour, fill = on_colour)
    if is_hidden :
      canvas.itemconfig(hdl, state = HIDDEN)

    return hdl

  #
  # Create a polygon object for a seven segment display middle segment
  #
  @staticmethod
  def __createMidPoly (canvas, x, y, on_colour, is_hidden) :
    hdl = canvas.create_polygon (x+0, y+1, x+2, y+0, x+6, y+0, x+8, y+1, x+6, y+3, x+2, y+3,
                                outline = on_colour, fill = on_colour)
    if is_hidden :
      canvas.itemconfig(hdl, state = HIDDEN)

    return hdl

  #
  # Create a polygon object for a seven segment display top segment
  #
  @staticmethod
  def __createTopPoly (canvas, x, y, on_colour, is_hidden) :
    hdl = canvas.create_polygon (x+0, y+0, x+10, y+0, x+8, y+2, x+2, y+2, outline = on_colour, fill = on_colour)
    if is_hidden :
      canvas.itemconfig(hdl, state = HIDDEN)

    return hdl

  #
  # Create a polygon object for a seven segment display bottom segment
  #
  @staticmethod
  def __createBottomPoly (canvas, x, y, on_colour, is_hidden) :
    hdl = canvas.create_polygon (x+0, y+2, x+2, y+0, x+8, y+0, x+9, y+2, outline = on_colour, fill = on_colour)
    if is_hidden :
      canvas.itemconfig(hdl, state = HIDDEN)

    return hdl

  #
  # Create the polygons for a whole seven degment display
  #
  def __createSeg7 (self, canvas, x, y, init_pattern) :

    # Create all seven segments of the display, and place object IDs in a list.
    # The order matches the DE1 boards connections to the FPGA ports, so that
    # the control value here is the same as that on the development board.
    hdl_list = [self.__createTopPoly   (canvas, x + 6,  y + 0,  de1gui.colours['red'], init_pattern & 0x01),
                self.__createRightPoly (canvas, x + 14, y + 1,  de1gui.colours['red'], init_pattern & 0x02),
                self.__createRightPoly (canvas, x + 12, y + 12, de1gui.colours['red'], init_pattern & 0x04),
                self.__createBottomPoly(canvas, x + 3,  y + 21, de1gui.colours['red'], init_pattern & 0x08),
                self.__createLeftPoly  (canvas, x + 0,  y + 12, de1gui.colours['red'], init_pattern & 0x10),
                self.__createLeftPoly  (canvas, x + 2,  y + 1,  de1gui.colours['red'], init_pattern & 0x20),
                self.__createMidPoly   (canvas, x + 4,  y + 10, de1gui.colours['red'], init_pattern & 0x40)]

    # return list of object handles
    return hdl_list

  #
  # Create the polygons for all 4 seven segment displays
  #
  def __createSeg7block (self, canvas, x, y, init_pattern_str) :

    # Ensure initial on/off pattern string argument to be
    # four characters, truncating long strings, and padding
    # short strings
    pstr = init_pattern_str
    if len(pstr) < 4 :
      pstr = ' ' * (4 - len(pstr)) + pstr
    else :
      if len(pstr) > 4 :
        pstr = pstr[0:4]

    # Separate the 4 charaters of the parsed string to a list of individual
    # characters
    pattern_list = list(pstr)

    # Create the four displays in the block, constructing a list of the returned
    # lists of the segment object handles: seg_hdl[4][7]
    seg7_hdls = [self.__createSeg7(canvas, x + 0,  y, de1gui.seg_dict[pattern_list[0]]),
                 self.__createSeg7(canvas, x + 22, y, de1gui.seg_dict[pattern_list[1]]),
                 self.__createSeg7(canvas, x + 45, y, de1gui.seg_dict[pattern_list[2]]),
                 self.__createSeg7(canvas, x + 67, y, de1gui.seg_dict[pattern_list[3]])]

    # Return the list of handles
    return seg7_hdls

  #
  # Create an individual LED
  #
  @staticmethod
  def __createLed(canvas, coords, on_colour, on) :

    # Extract the individual x and y co-ordinates from the passed in tuple
    x, y = coords

    # Create the LED object
    hdl = canvas.create_rectangle(x, y, x+5, y+9, outline=on_colour, fill=on_colour)

    # If initial state is not on, then hide the object
    if not on :
      canvas.itemconfig (hdl, state = HIDDEN)

    return hdl

  #
  # Create a block of 8 green LEDs
  #
  def __createLedGreenBlock(self, canvas, init_pattern) :

    # Create the 8 LEDs, and gather hndles into a list
    hdl_list = [self.__createLed(canvas, de1gui.led_origins['ledg0'], de1gui.colours['green'], init_pattern & 0x01),
                self.__createLed(canvas, de1gui.led_origins['ledg1'], de1gui.colours['green'], init_pattern & 0x02),
                self.__createLed(canvas, de1gui.led_origins['ledg2'], de1gui.colours['green'], init_pattern & 0x04),
                self.__createLed(canvas, de1gui.led_origins['ledg3'], de1gui.colours['green'], init_pattern & 0x08),
                self.__createLed(canvas, de1gui.led_origins['ledg4'], de1gui.colours['green'], init_pattern & 0x10),
                self.__createLed(canvas, de1gui.led_origins['ledg5'], de1gui.colours['green'], init_pattern & 0x20),
                self.__createLed(canvas, de1gui.led_origins['ledg6'], de1gui.colours['green'], init_pattern & 0x40),
                self.__createLed(canvas, de1gui.led_origins['ledg7'], de1gui.colours['green'], init_pattern & 0x80)]

    # Return this list of handles
    return hdl_list

  #
  # Create a block of 10 red LEDs
  #
  def __createLedRedBlock(self, canvas, pattern) :

    # Create the 8 LEDs, and gather hndles into a list
    hdl_list = [self.__createLed(canvas, de1gui.led_origins['ledr0'], de1gui.colours['red'],   pattern & 0x001),
                self.__createLed(canvas, de1gui.led_origins['ledr1'], de1gui.colours['red'],   pattern & 0x002),
                self.__createLed(canvas, de1gui.led_origins['ledr2'], de1gui.colours['red'],   pattern & 0x004),
                self.__createLed(canvas, de1gui.led_origins['ledr3'], de1gui.colours['red'],   pattern & 0x008),
                self.__createLed(canvas, de1gui.led_origins['ledr4'], de1gui.colours['red'],   pattern & 0x010),
                self.__createLed(canvas, de1gui.led_origins['ledr5'], de1gui.colours['red'],   pattern & 0x020),
                self.__createLed(canvas, de1gui.led_origins['ledr6'], de1gui.colours['red'],   pattern & 0x040),
                self.__createLed(canvas, de1gui.led_origins['ledr7'], de1gui.colours['red'],   pattern & 0x008),
                self.__createLed(canvas, de1gui.led_origins['ledr8'], de1gui.colours['red'],   pattern & 0x100),
                self.__createLed(canvas, de1gui.led_origins['ledr9'], de1gui.colours['red'],   pattern & 0x200)]

    return hdl_list

  #
  # Callback on clicking the power button
  #
  def __onPwrClick (self, dummy) :
    self.root.quit()
    self.root.destroy()

  #
  # Create a power button obect, and bind a callback functoin
  # when a mouse clicked over it.
  #
  def __createPwrButton(self, canvas, x, y) :
    hdl = canvas.create_oval(x+0,y+0,x+19,y+19, fill='#f52425', outline='#f52425')
    #canvas.itemconfig (hdl, state = HIDDEN)
    canvas.tag_bind(hdl, '<ButtonPress-1>', self.__onPwrClick)
    return hdl

  #
  # Update a seven segment display (hdl_list contains handle set
  # for a given segment)
  #
  @staticmethod
  def __updateSeg7(canvas, hdl_list, off_pattern) :

    for idx in range(0, 7) :
      if off_pattern & (1 << idx) :
        canvas.itemconfig (hdl_list[idx], state = HIDDEN)
      else :
        canvas.itemconfig (hdl_list[idx], state = NORMAL)

  #
  # Update the seven segment display block. hdl_list contains
  # a list of each of the four segment's handle list.
  #
  def __updateSeg7Block(self, canvas, hdl_list, pattern_str) :

    # Ensure initial on/off pattern string argument to be
    # four characters, truncating long strings, and padding
    # short strings
    pstr = pattern_str
    if len(pstr) < 4 :
      pstr = ' ' * (4 - len(pstr)) + pstr
    else :
      if len(pstr) > 4 :
        pstr = pstr[0:4]

    # Separate the 4 charaters of the parsed string to a list of individual
    # characters
    pattern_list = list(pstr)

    # Update each segment in turn, converting the patter character to the
    # on/off pattern via the seg_dict dictionary
    for idx in range(0, 4) :
      self.__updateSeg7(canvas, hdl_list[idx], de1gui.seg_dict[pattern_list[idx]])

  #
  #
  #
  @staticmethod
  def __updateLedGreenBlock(canvas, hdl_list, on_pattern) :

    for idx in range (0, 8) :
      if on_pattern & (1 << idx) :
        canvas.itemconfig (hdl_list[idx], state = NORMAL)
      else :
        canvas.itemconfig (hdl_list[idx], state = HIDDEN)

  #
  #
  #
  @staticmethod
  def __updateLedRedBlock(canvas, hdl_list, on_pattern) :

    for idx in range (0, 10) :
      if on_pattern & (1 << idx) :
        canvas.itemconfig (hdl_list[idx], state = NORMAL)
      else :
        canvas.itemconfig (hdl_list[idx], state = HIDDEN)

  #
  # DE1 GUI's loop. Will execute any internal code,
  # and then reschedule a call to itself after 'delay'
  # milliseconds
  #
  def __de1GuiLoop (self, delay = 1000) :

    self.loop_count += 1
    #print('Loop count = ' + str(self.loop_count))

    #### PUT FUNCTION CALLS HERE ####
    status = True

    # Whist receiving message, keep processing them
    while status :
      status = self.__checkForMsg(self.canvas, self.seg7_hdls)

    #### --------- END --------- ####

    # Reschedule a callback for this function and return
    self.root.after(delay, self.__de1GuiLoop)

  #
  # Setup up a server side socket
  #
  def __setupTcpServer (self) :

    self.skt = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    self.skt.bind((de1gui.TCP_IP, de1gui.TCP_PORT))

  #
  # Check the TCP socket for a message and, if a message
  # received, update the display accordingly.
  #
  def __checkForMsg(self, canvas, seg7_hdls) :

    if not self.tcpOpen :
      try :
        self.skt.settimeout(0.2)
        self.skt.listen(1)
        self.conn, addr = self. skt.accept()
      except :
        return

      self.conn.setblocking(0)
      self.tcpOpen = True

    msg    = None
    status = False

    # Using the select module, detrmine if there is anything waiting
    # to be read from the connection
    ready = select.select([self.conn], [], [], 0.1)

    # If ready, receive the message
    if ready[0] :
      msg = self.conn.recv(256)

    # If there was a message received, convert bytes to a string and
    # update the GUI display
    if not msg is None :

     # Decode bytes to a UTF-8 string, and split the commands
     # into a list (delimited on ';')
      msg_str_decode = msg.decode('utf-8')
      msg_str_list = msg_str_decode.split(';')

      # Loop through the messages (maybe only one).
      for msg_str in msg_str_list :

        # Only process commands that have at least two characters
        if len(msg_str) > 1 :

          if   msg_str[0] == 'S' :
            self.__updateSeg7Block(canvas, seg7_hdls, msg_str[1:])
            status = True
          elif msg_str[0] == 'G' :
            self.__updateLedGreenBlock(canvas, self.led_hdls[0], int(msg_str[1:]))
            status = True
          elif msg_str[0] == 'R' :
            self.__updateLedRedBlock(canvas, self.led_hdls[1], int(msg_str[1:]))
            status = True
          elif msg_str[0] == 'c' and msg_str[1] == 'l' and msg_str[2] == 'o' and \
               msg_str[3] == 's' and msg_str[4] == 'e' :
            self.__onPwrClick(0)
          elif msg_str[0] == 'r' and msg_str[1] == 'e' and msg_str[2] == 's' and \
               msg_str[3] == 'e' and msg_str[4] == 't' :     
            self.__updateSeg7Block    (canvas, seg7_hdls,        de1.SEG7_reset)
            self.__updateLedRedBlock  (canvas, self.led_hdls[1], de1.LEDR_reset)
            self.__updateLedGreenBlock(canvas, self.led_hdls[1], de1.LEDG_reset)

    return status
  #
  # Create the widgets for this class
  #
  def __createWidgets (self, top) :

    # Create a canvas to draw on, and add to grid
    self.canvas = Canvas(master = top,  width  = de1gui.canvas_dimensions['width'],
                                        height = de1gui.canvas_dimensions['height'])
    self.canvas.grid(row = 0, column = 0)

    # Open the background image
    try :
      self.img = PhotoImage(file = self.scriptdir.get() + '/' + 'de1.gif')
    except :
      return

    # Add the image to the canvas. The 'origin' of this appears to
    # have to be in the middle of the canvas. This isn't true when
    # calculating the co-ordinates of the polygons,  which seem to
    # have the origin at the top left of the canvas.
    self.canvas.create_image(de1gui.canvas_dimensions['height']/2,
                             de1gui.canvas_dimensions['width']/2,
                             image = self.img)

    # Create the seven segment display polygons
    self.seg7_hdls = self.__createSeg7block(self.canvas, de1gui.seg7_origin['x'], de1gui.seg7_origin['y'], de1.SEG7_reset)

    # Create the LED polygons
    self.led_hdls  = [self.__createLedGreenBlock(self.canvas, de1.LEDR_reset),
                      self.__createLedRedBlock  (self.canvas, de1.LEDR_reset)]

    # Create a power button object
    self._pwr_hdl = self.__createPwrButton(self.canvas, 32, 105)

    # Set up a server TCP socket
    self.__setupTcpServer()

    # Start the GUI's loop, with a specified delay (ms)
    self.__de1GuiLoop(delay = de1gui.del_gui_loop_delay)

    # Start the event loop
    mainloop()    
  
  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # 'Public' methods
  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
  
  # run()
  #
  # Top level method to create application window, and generate output
  #  
  def run(self):
  
    # Create the application GUI
    self.__createWidgets(self.root)
    
# ###############################################################
# Only run if not imported
#
if __name__ == '__main__' :
  
  de1 = de1gui()
  de1.run()    