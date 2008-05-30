/*
 *  GarminConstants.h
 *  GPSTest
 *
 *  Constants specific to the Garmin Protocol.
 *
 *  Created by Ryan on Sat May 29 2004.
 *  Copyright (c) 2004 Chimoosoft. All rights reserved.
 *
 */
//  ********
//  Disclaimer: Terrabrowser was one of the first Cocoa programs I wrote and
//  as such, it is in no way representative of my current coding style! ;-) 
//  Many things are done incorrectly in this code base but I have not taken the
//  time to revise them for the open source release. There are also many compile
//  time warnings which should be corrected as some of them hint at serious problems.
//  If you work for a company looking to hire me, don't look too critically at this old code!
//  Similarly, if you're trying to learn Cocoa / Objective-C, keep this in mind.
//  ********

//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.


typedef enum {
	Pid_Ack_Byte		= 6,
	Pid_Almanac_Data	= 31,
	Pid_Command_Data	= 10,
	Pid_Date_Time_Data  = 14,
	Pid_Nak_Byte		= 21,
	Pid_Position_Data   = 17,
	Pid_Product_Data	= 255,
	Pid_Product_Rqst	= 254,
	Pid_Protocol_Array  = 253,
	Pid_Prx_Wpt_Data	= 19,
	Pid_Pvt_Data		= 51,
	Pid_Records			= 27,
	Pid_Rte_Hdr			= 29,
	Pid_Rte_Link_Data   = 98,
	Pid_Rte_Wpt_Data	= 30,
	Pid_Trk_Data		= 34,
	Pid_Trk_Hdr			= 99,
	Pid_Wpt_Data		= 35,
	Pid_Xfer_Cmplt		= 12
} GarminPid;


typedef enum {
	Cmnd_Abort_Transfer		= 0,
	Cmnd_Start_Pvt_Data		= 49,
	Cmnd_Stop_Pvt_Data		= 50,
	Cmnd_Transfer_Alm		= 1,
	Cmnd_Transfer_Posn		= 2,
	Cmnd_Transfer_Prx		= 3,
	Cmnd_Transfer_Rte		= 4,
	Cmnd_Transfer_Time		= 5,
	Cmnd_Transfer_Trk		= 6,
	Cmnd_Transfer_Wpt		= 7,
	Cmnd_Turn_Off_Power		= 8
} GarminCmnd;

typedef enum {
	UPLOAD_MODE		= 1,
	DOWNLOAD_MODE   = 0
} GPSMode;

static const int UPLOAD_WAYPOINT_TYPE = 0;

// for the D800 PVT data type
typedef enum {
	unusable	= 0,		/* failed integrity check			*/
	invalid		= 1,		/* invalid or unavailable			*/
	twoD		= 2,		/* two dimensional					*/
	threeD		= 3,		/* three dimensional				*/
	twoD_diff   = 4,		/* two dimensional differential		*/
	threeD_diff = 5			/* three dimensional differential   */
} GarminFixType;



