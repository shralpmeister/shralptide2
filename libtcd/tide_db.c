/* $Id: tide_db.c 3176 2008-08-20 23:36:01Z flaterco $ */

#include "tcd.h"
#include "tide_db_header.h"
#include "tide_db_default.h"

/* This should be done with stdbool.h, but VC doesn't have it. */
/* Using crappy old int, must be careful not to 'require' a 64-bit value. */
#ifndef require
#define require(expr) {       \
  int require_expr;           \
  require_expr = (int)(expr); \
  assert (require_expr);      \
}
#endif

#ifdef NDEBUG
#ifdef USE_PRAGMA_MESSAGE
#pragma message("WARNING:  NDEBUG is defined.  This configuration is unsupported and discouraged.")
#else
#warning NDEBUG is defined.  This configuration is unsupported and discouraged.
#endif
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <math.h>
#include <ctype.h>
#include <assert.h>

//#ifdef HAVE_UNISTD_H
#include <unistd.h>
//#endif

#ifdef HAVE_IO_H
#include <io.h>
#endif


/*****************************************************************************\

                            DISTRIBUTION STATEMENT

    This source file is unclassified, distribution unlimited, public
    domain.  It is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

\*****************************************************************************/



/* Some of the following commentary is out of date.  See the new
   documentation in libtcd.html. */

/*****************************************************************************\

    Tide Constituent Database API


    Author  : Jan C. Depner (depnerj@navo.navy.mil)

    Date    : 08/01/02
              (First day of Micro$oft's "Licensing 6" policy - P.T. Barnum was
              right!!!)

    Purpose : To replace the ASCII/XML formatted harmonic constituent data
              files, used in Dave Flater's (http://www.flaterco.com/xtide/)
              exceptionally fine open-source XTide program, with a fast,
              efficient binary format.  In addition, we wanted to replace the
              Naval Oceanographic Office's (http://www.navo.navy.mil)
              antiquated ASCII format harmonic constituent data file due to
              problems with configuration management of the file.  The
              resulting database will become a Navy OAML (Oceanographic and
              Atmospheric Master Library) standard harmonic tide constituent
              database.

    Design  : The following describes the database file and some of the
              rationale behind the design.

    First question - Why didn't I use PostgreSQL or MySQL?  Mostly
    portability.  What?  PostgreSQL runs on everything!  Yes, but it doesn't
    come installed on everything.  This would have meant that the poor,
    benighted Micro$oft borgs would have had to actually load a software
    package.  In addition, the present harmonics/offset files only contain
    a total of 6,409 stations.  It hardly seemed worth the effort (or overhead)
    of a fullblown RDBMS to handle this.  Second question - Why binary and not
    ASCII or XML?  This actually gets into philosophy.  At NAVO we have used an
    ASCII harmonic constituent file for years (we were founded in 1830 and I
    think that that's when they designed the file).  We have about fifty
    million copies floating around and each one is slightly different.  Why?
    Because they're ASCII and everyone thinks they know what they're doing so
    they tend to modify the file.  Same problem with XML, it's still ASCII.
    We wanted a file that people weren't going to mess with and that we could
    version control.  We also wanted a file that was small and fast.  This is
    very difficult to do with ASCII.  The big slowdown with the old format
    was I/O and parsing.  Third question - will it run on any OS?  Hopefully,
    yes.  After twenty-five years of working with low bidder systems I've
    worked on almost every OS known to man.  Once you've been bitten by big
    endian vs little endian or IEEE floating point format vs VAX floating
    point format or byte addressable memory vs word addressable memory or 32
    bit word vs 36 bit word vs 48 bit word vs 64 bit word sizes you get the
    message.  All of the data in the file is stored either as ASCII text or
    scaled integers (32 bits or smaller), bit-packed and stuffed into an
    unsigned character buffer for I/O.  No endian issues, no floating point
    issues, no word size issues, no memory mapping issues.  I will be testing
    this on x86 Linux, HP-UX, and Micro$oft Windoze.  By the time you read
    this it will be portable to those systems at least.

    Now, on to the file layout.  As much as I dislike ASCII it is occasionally
    handy to be able to see some information about a file without having to
    resort to a special purpose program.  With that in mind I made the first
    part of the header of the file ASCII.  The following is an example of the
    ASCII portion of the header:

        [VERSION] = PFM Software - tide_db V1.00 - 08/01/02
        [LAST MODIFIED] = Thu Aug  1 02:46:29 2002
        [HEADER SIZE] = 4096
        [NUMBER OF RECORDS] = 10652
        [START YEAR] = 1970
        [NUMBER OF YEARS] = 68
        [SPEED BITS] = 31
        [SPEED SCALE] = 10000000
        [SPEED OFFSET] = -410667
        [EQUILIBRIUM BITS] = 16
        [EQUILIBRIUM SCALE] = 100
        [EQUILIBRIUM OFFSET] = 0
        [NODE BITS] = 15
        [NODE SCALE] = 10000
        [NODE OFFSET] = -3949
        [AMPLITUDE BITS] = 19
        [AMPLITUDE SCALE] = 10000
        [EPOCH BITS] = 16
        [EPOCH SCALE] = 100
        [RECORD TYPE BITS] = 4
        [LATITUDE BITS] = 25
        [LATITUDE SCALE] = 100000
        [LONGITUDE BITS] = 26
        [LONGITUDE SCALE] = 100000
        [RECORD SIZE BITS] = 12
        [STATION BITS] = 18
        [DATUM OFFSET BITS] = 32
        [DATUM OFFSET SCALE] = 10000
        [DATE BITS] = 27
        [MONTHS ON STATION BITS] = 10
        [CONFIDENCE VALUE BITS] = 4
        [TIME BITS] = 13
        [LEVEL ADD BITS] = 16
        [LEVEL ADD SCALE] = 100
        [LEVEL MULTIPLY BITS] = 16
        [LEVEL MULTIPLY SCALE] = 1000
        [DIRECTION BITS] = 9
        [LEVEL UNIT BITS] = 3
        [LEVEL UNIT TYPES] = 6
        [LEVEL UNIT SIZE] = 15
        [DIRECTION UNIT BITS] = 2
        [DIRECTION UNIT TYPES] = 3
        [DIRECTION UNIT SIZE] = 15
        [RESTRICTION BITS] = 4
        [RESTRICTION TYPES] = 2
        [RESTRICTION SIZE] = 30
        [PEDIGREE BITS] = 6
        [PEDIGREE TYPES] = 13
        [PEDIGREE SIZE] = 60
        [DATUM BITS] = 7
        [DATUM TYPES] = 61
        [DATUM SIZE] = 70
        [CONSTITUENT BITS] = 8
        [CONSTITUENTS] = 173
        [CONSTITUENT SIZE] = 10
        [COUNTRY BITS] = 9
        [COUNTRIES] = 240
        [COUNTRY SIZE] = 50
        [TZFILE BITS] = 10
        [TZFILES] = 449
        [TZFILE SIZE] = 30
        [END OF FILE] = 2585170
        [END OF ASCII HEADER DATA]

    Most of these values will make sense in the context of the following
    description of the rest of the file.  Some caveats on the data storage -
    if no SCALE is listed for a field, the scale is 1.  If no BITS field is
    listed, this is a variable length character field and is stored as 8 bit
    ASCII characters.  If no OFFSET is listed, the offset is 0.  Offsets are
    scaled.  All SIZE fields refer to the maximum length, in characters, of a
    variable length character field.  Some of the BITS fields are calculated
    while others are hardwired (see code).  For instance, [DIRECTION BITS] is
    hardwired because it is an integer field whose value can only be from 0 to
    361 (361 = no direction flag).  [NODE BITS], on the other hand, is
    calculated on creation by checking the min, max, and range of all of the
    node factor values.  The number of bits needed is easily calculated by
    taking the log of the adjusted, scaled range, dividing by the log of 2 and
    adding 1.  Immediately following the ASCII portion of the header is a 32
    bit checksum of the ASCII portion of the header.  Why?  Because some
    genius always gets the idea that he/she can modify the header with a text
    or hex editor.  Go figure.

    The rest of the header is as follows :

        [LEVEL UNIT TYPES] fields of [LEVEL UNIT SIZE] characters, each field
            is internally 0 terminated (anything after the zero is garbage)

        [DIRECTION UNIT TYPES] fields of [DIRECTION UNIT SIZE] characters, 0
            terminated

        [RESTRICTION TYPES] fields of [RESTRICTION SIZE] characters, 0
            terminated

        [PEDIGREE TYPES] fields of [PEDIGREE SIZE] characters, 0 terminated

        [TZFILES] fields of [TZFILE SIZE] characters, 0 terminated

        [COUNTRIES] fields of [COUNTRY SIZE] characters, 0 terminated

        [DATUM TYPES] fields of [DATUM SIZE] characters, 0 terminated

        [CONSTITUENTS] fields of [CONSTITUENT SIZE] characters, 0 terminated
            Yes, I know, I wasted some space with these fields but I wasn't
            worried about a couple of hundred bytes.

        [CONSTITUENTS] fields of [SPEED BITS], speed values (scaled and offset)

        [CONSTITUENTS] groups of [NUMBER OF YEARS] fields of
            [EQUILIBRIUM BITS], equilibrium arguments (scaled and offset)

        [CONSTITUENTS] groups of [NUMBER OF YEARS] fields of [NODE BITS], node
            factors (scaled and offset)


    Finally, the data.  At present there are two types of records in the file.
    These are reference stations (record type 1) and subordinate stations
    (record type 2).  Reference stations contain a set of constituents while
    subordinate stations contain a number of offsets to be applied to the
    reference station that they are associated with.  Note that reference
    stations (record type 1) may, in actuality, be subordinate stations, albeit
    with a set of constituents.  All of the records have the following subset
    of information stored as the first part of the record:

        [RECORD SIZE BITS] - record size in bytes
        [RECORD TYPE BITS] - record type (1 or 2)
        [LATITUDE BITS] - latitude (degrees, south negative, scaled & offset)
        [LONGITUDE BITS] - longitude (degrees, west negative, scaled & offset)
        [TZFILE BITS] - index into timezone array (retrieved from header)
        variable size - station name, 0 terminated
        [STATION BITS] - record number of reference station or -1
        [COUNTRY_BITS] index into country array (retrieved from header)
        [PEDIGREE BITS] - index into pedigree array (retrieved from header)
        variable size - source, 0 terminated
        [RESTRICTION BITS] - index into restriction array
        variable size - comments, may contain LFs to indicate newline (no CRs)


    These are the rest of the fields for record type 1:

        [LEVEL UNIT BITS] - index into level units array
        [DATUM OFFSET BITS] - datum offset (scaled)
        [DATUM BITS] - index into datum name array
        [TIME BITS] - time zone offset from GMT0 (meridian, integer +/-HHMM)
        [DATE BITS] - expiration date, (integer YYYYMMDD, default is 0)
        [MONTHS ON STATION BITS] - months on station
        [DATE BITS] - last date on station, default is 0
        [CONFIDENCE BITS] - confidence value (TBD)
        [CONSTITUENT BITS] - "N", number of constituents for this station

        N groups of:
            [CONSTITUENT BITS] - constituent number
            [AMPLITUDE BITS] - amplitude (scaled & offset)
            [EPOCH BITS] - epoch (scaled & offset)


    These are the rest of the fields for record type 2:

        [LEVEL UNIT BITS] - leveladd units, index into level_units array
        [DIRECTION UNIT BITS] - direction units, index into dir_units array
        [LEVEL UNIT BITS] - avglevel units, index into level_units array
        [TIME BITS] - min timeadd (integer +/-HHMM) or 0
        [LEVEL ADD BITS] - min leveladd (scaled) or 0
        [LEVEL MULTIPLY BITS] - min levelmultiply (scaled) or 0
        [LEVEL ADD BITS] - min avglevel (scaled) or 0
        [DIRECTION BITS] - min direction (0-360 or 361 for no direction)
        [TIME BITS] - max timeadd (integer +/-HHMM) or 0
        [LEVEL ADD BITS] - max leveladd (scaled) or 0
        [LEVEL MULTIPLY BITS] - max levelmultiply (scaled) or 0
        [LEVEL ADD BITS] - max avglevel (scaled) or 0
        [DIRECTION BITS] - max direction (0-360 or 361 for no direction)
        [TIME BITS] - floodbegins (integer +/-HHMM) or NULLSLACKOFFSET
        [TIME BITS] - ebbbegins (integer +/-HHMM) or NULLSLACKOFFSET


    Back to philosophy!  When you design a database of any kind the first
    thing you should ask yourself is "Self, how am I going to access this
    data most of the time?".  If you answer yourself out loud you should
    consider seeing a shrink.  99 and 44/100ths percent of the time this
    database is going to be read to get station data.  The other 66/100ths
    percent of the time it will be created/modified.  Variable length records
    are no problem on retrieval.  They are no problem to create.  They can be
    a major pain in the backside if you have to modify/delete them.  Since we
    shouldn't be doing too much editing of the data (usually just adding
    records) this is a pretty fair design.  At some point though we are going
    to want to modify or delete a record.  There are two possibilities here.
    We can dump the database to an ASCII file or files using restore_tide_db,
    use a text editor to modify them, and then rebuild the database.  The
    other possibility is to modify the record in place.  This is OK if you
    don't change a variable length field but what if you want to change the
    station name or add a couple of constituents?  With the design as is we
    have to read the remainder of the file from the end of the record to be
    modified, write the modified record, rewrite the remainder of the file,
    and then change the end_of_file pointer in the header.  So, which fields
    are going to be a problem?  Changes to station name, source, comments, or
    the number of constituents for a station will require a resizing of the
    database.  Changes to any of the other fields can be done in place.  The
    worst thing that you can do though is to delete a record.  Not just
    because the file has to be resized but because it might be a reference
    record with subordinate stations.  These would have to be deleted as well.
    The delete_tide_record function will do just that so make sure you check
    before you call it.  You might not want to do that.

    Another point to note is that when you open the database the records are
    indexed at that point.  This takes about half a second on a dual 450.
    Most applications use the header part of the record very often and
    the rest of the record only if they are going to actually produce
    predicted tides.  For instance, XTide plots all of the stations on a
    world map or globe and lists all of the station names.  It also needs the
    timezone up front.  To save re-indexing to get these values I save them
    in memory.  The only time an application needs to actually read an entire
    record is when you want to do the prediction.  Otherwise just use
    get_partial_tide_record or get_next_partial_tide_record to yank the good
    stuff out of memory.

    'Nuff said?


    See libtcd.html for changelog.

\*****************************************************************************/

/* Maintenance by DWF */


/*  Function prototypes.  */

NV_U_INT32 calculate_bits (NV_U_INT32 value);
void bit_pack (NV_U_BYTE *, NV_U_INT32, NV_U_INT32, NV_INT32);
NV_U_INT32 bit_unpack (NV_U_BYTE *, NV_U_INT32, NV_U_INT32);
NV_INT32 signed_bit_unpack (NV_U_BYTE buffer[], NV_U_INT32 start,
                            NV_U_INT32 numbits);



/*  Global variables.  */

typedef struct
{
    NV_INT32                address;
    NV_U_INT32              record_size;
    NV_U_INT16              tzfile;
    NV_INT32                reference_station;
    NV_INT32                lat;
    NV_INT32                lon;
    NV_U_BYTE               record_type;
    NV_CHAR                 *name;
} TIDE_INDEX;


static FILE                 *fp = NULL;
static TIDE_INDEX           *tindex = NULL;
static NV_BOOL              modified = NVFalse;
static NV_INT32             current_record, current_index;
static NV_CHAR              filename[MONOLOGUE_LENGTH];


/*****************************************************************************\
  Checked fread and fwrite wrappers
  DWF 2007-12-02

  Fedora package compiles generate warnings for invoking these
  functions without checking the return.
\*****************************************************************************/

static void chk_fread (void *ptr, size_t size, size_t nmemb, FILE *stream) {
  size_t ret;
  ret = fread (ptr, size, nmemb, stream);
  if (ret != nmemb) {
    fprintf (stderr, "libtcd unexpected error: fread failed\n");
    fprintf (stderr, "nmemb = %lu, got %lu\n", nmemb, ret);
    abort();
  }
}

static void chk_fwrite (const void *ptr, size_t size, size_t nmemb,
			FILE *stream) {
  size_t ret;
  ret = fwrite (ptr, size, nmemb, stream);
  if (ret != nmemb) {
    fprintf (stderr, "libtcd unexpected error: fwrite failed\n");
    fprintf (stderr, "nmemb = %lu, got %lu\n", nmemb, ret);
    fprintf (stderr, "The database is probably corrupt now.\n");
    abort();
  }
}


/*****************************************************************************\

    Function        dump_tide_record - prints out all of the fields in the
                    input tide record

    Synopsis        dump_tide_record (rec);

                    TIDE_RECORD *rec        pointer to the tide record

    Returns         void

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

void dump_tide_record (TIDE_RECORD *rec)
{
    NV_U_INT32              i;

    assert (rec);

    fprintf (stderr, "\n\nRecord number = %d\n", rec->header.record_number);
    fprintf (stderr, "Record size = %u\n", rec->header.record_size);
    fprintf (stderr, "Record type = %u\n", rec->header.record_type);
    fprintf (stderr, "Latitude = %f\n", rec->header.latitude);
    fprintf (stderr, "Longitude = %f\n", rec->header.longitude);
    fprintf (stderr, "Reference station = %d\n",
        rec->header.reference_station);
    fprintf (stderr, "Tzfile = %s\n", get_tzfile (rec->header.tzfile));
    fprintf (stderr, "Name = %s\n", rec->header.name);

    fprintf (stderr, "Country = %s\n", get_country (rec->country));
    fprintf (stderr, "Source = %s\n", rec->source);
    fprintf (stderr, "Restriction = %s\n", get_restriction (rec->restriction));
    fprintf (stderr, "Comments = %s\n", rec->comments);
    fprintf (stderr, "Notes = %s\n", rec->notes);
    fprintf (stderr, "Legalese = %s\n",
        get_legalese (rec->legalese));
    fprintf (stderr, "Station ID context = %s\n", rec->station_id_context);
    fprintf (stderr, "Station ID = %s\n", rec->station_id);
    fprintf (stderr, "Date imported = %d\n", rec->date_imported);
    fprintf (stderr, "Xfields = %s\n", rec->xfields);

    fprintf (stderr, "Direction units = %s\n",
        get_dir_units (rec->direction_units));
    fprintf (stderr, "Min direction = %d\n", rec->min_direction);
    fprintf (stderr, "Max direction = %d\n", rec->max_direction);
    fprintf (stderr, "Level units = %s\n", get_level_units (rec->level_units));

    if (rec->header.record_type == REFERENCE_STATION)
    {
        fprintf (stderr, "Datum offset = %f\n", rec->datum_offset);
        fprintf (stderr, "Datum = %s\n", get_datum (rec->datum));
        fprintf (stderr, "Zone offset = %d\n", rec->zone_offset);
        fprintf (stderr, "Expiration date = %d\n", rec->expiration_date);
        fprintf (stderr, "Months on station = %d\n", rec->months_on_station);
        fprintf (stderr, "Last date on station = %d\n",
            rec->last_date_on_station);
        fprintf (stderr, "Confidence = %d\n", rec->confidence);
        for (i = 0 ; i < hd.pub.constituents ; ++i)
        {
            if (rec->amplitude[i] != 0.0 || rec->epoch[i] != 0.0)
            {
                fprintf (stderr, "Amplitude[%d] = %f\n", i, rec->amplitude[i]);
                fprintf (stderr, "Epoch[%d] = %f\n", i, rec->epoch[i]);
            }
        }
    }

    else if (rec->header.record_type == SUBORDINATE_STATION)
    {
        fprintf (stderr, "Min time add = %d\n", rec->min_time_add);
        fprintf (stderr, "Min level add = %f\n", rec->min_level_add);
        fprintf (stderr, "Min level multiply = %f\n", rec->min_level_multiply);
        fprintf (stderr, "Max time add = %d\n", rec->max_time_add);
        fprintf (stderr, "Max level add = %f\n", rec->max_level_add);
        fprintf (stderr, "Max level multiply = %f\n", rec->max_level_multiply);
        fprintf (stderr, "Flood begins = %d\n", rec->flood_begins);
        fprintf (stderr, "Ebb begins = %d\n", rec->ebb_begins);
    }
}


/*****************************************************************************\

    Function        write_protect - prevent trying to modify TCD files of
                    an earlier version.  Nothing to do with file locking.

    David Flater, 2004-10-14.

\*****************************************************************************/

static void write_protect () {
  if (hd.pub.major_rev < LIBTCD_MAJOR_REV) {
    fprintf (stderr, "libtcd error: can't modify TCD files created by earlier version.  Use\nrewrite_tide_db to upgrade the TCD file.\n");
    exit (-1);
  }
}


/*****************************************************************************\

    Function        get_country - gets the country field for record "num"

    Synopsis        get_country (num);

                    NV_INT32 num            tide record number

    Returns         NV_CHAR *               country name (associated with
                                            ISO 3166-1:1999 2-character
                                            country code

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_CHAR *get_country (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  if (num >= 0 && num < (NV_INT32)hd.pub.countries) return (hd.country[num]);
  return ("Unknown");
}


/*****************************************************************************\

    Function        get_tzfile - gets the time zone name for record "num"

    Synopsis        get_tzfile (num);

                    NV_INT32 num            tide record number

    Returns         NV_CHAR *               time zone name used in TZ variable

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_CHAR *get_tzfile (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  if (num >= 0 && num < (NV_INT32)hd.pub.tzfiles) return (hd.tzfile[num]);
  return ("Unknown");
}


/*****************************************************************************\

    Function        get_station - get the name of the station for record "num"

    Synopsis        get_station (num);

                    NV_INT32 num            tide record number

    Returns         NV_CHAR *               station name

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_CHAR *get_station (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  if (num >= 0 && num < (NV_INT32)hd.pub.number_of_records) return (tindex[num].name);
  return ("Unknown");
}


/*****************************************************************************\

    Function        get_constituent - get the constituent name for constituent
                    number "num"

    Synopsis        get_constituent (num);

                    NV_INT32 num            constituent number

    Returns         NV_CHAR *               constituent name

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_CHAR *get_constituent (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  if (num >= 0 && num < (NV_INT32)hd.pub.constituents) return (hd.constituent[num]);
  return ("Unknown");
}


/*****************************************************************************\

    Function        get_level_units - get the level units for level units
                    number "num"

    Synopsis        get_level_units (num);

                    NV_INT32 num            level units number

    Returns         NV_CHAR *               units (ex. "meters");

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_CHAR *get_level_units (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  if (num >= 0 && num < (NV_INT32)hd.pub.level_unit_types) return (hd.level_unit[num]);
  return ("Unknown");
}


/*****************************************************************************\

    Function        get_dir_units - get the direction units for direction
                    units number "num"

    Synopsis        get_dir_units (num);

                    NV_INT32 num            direction units number

    Returns         NV_CHAR *               units (ex. "degrees true");

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_CHAR *get_dir_units (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  if (num >= 0 && num < (NV_INT32)hd.pub.dir_unit_types) return (hd.dir_unit[num]);
  return ("Unknown");
}


/*****************************************************************************\

    Function        get_restriction - gets the restriction description for
                    restriction number "num"

    Synopsis        get_restriction (num);

                    NV_INT32 num            restriction number

    Returns         NV_CHAR *               restriction (ex. "PUBLIC DOMAIN");

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_CHAR *get_restriction (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  if (num >= 0 && num < (NV_INT32)hd.pub.restriction_types)
      return (hd.restriction[num]);
  return ("Unknown");
}


/*****************************************************************************\

    Function        get_pedigree - gets the pedigree description for pedigree
                    number "num"

    Synopsis        get_pedigree (num);

                    NV_INT32 num            pedigree number

    Returns         NV_CHAR *               pedigree description

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

#ifdef COMPAT114
NV_CHAR *get_pedigree (NV_INT32 num) {
  return "Unknown";
}
#endif


/*****************************************************************************\

    Function        get_datum - gets the datum name for datum number "num"

    Synopsis        get_datum (num);

                    NV_INT32 num            datum number

    Returns         NV_CHAR *               datum name

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_CHAR *get_datum (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  if (num >= 0 && num < (NV_INT32)hd.pub.datum_types) return (hd.datum[num]);
  return ("Unknown");
}


/*****************************************************************************\
DWF 2004-10-14
\*****************************************************************************/
NV_CHAR *get_legalese (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  if (num >= 0 && num < (NV_INT32)hd.pub.legaleses) return (hd.legalese[num]);
  return ("Unknown");
}


/*****************************************************************************\

    Function        get_speed - gets the speed value for constituent number
                    "num"

    Synopsis        get_speed (num);

                    NV_INT32 num            constituent number

    Returns         NV_FLOAT64              speed

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_FLOAT64 get_speed (NV_INT32 num)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  assert (num >= 0 && num < (NV_INT32)hd.pub.constituents);
  return hd.speed[num];
}


/*****************************************************************************\

    Function        get_equilibrium - gets the equilibrium value for
                    constituent number "num" and year "year"

    Synopsis        get_equilibrium (num, year);

                    NV_INT32 num            constituent number
                    NV_INT32 year           year

    Returns         NV_FLOAT32              equilibrium argument

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_FLOAT32 get_equilibrium (NV_INT32 num, NV_INT32 year)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  assert (num >= 0 && num < (NV_INT32)hd.pub.constituents && year >= 0 && year < (NV_INT32)hd.pub.number_of_years);
  return hd.equilibrium[num][year];
}


/*****************************************************************************\
  DWF 2004-10-04
\*****************************************************************************/
NV_FLOAT32 *get_equilibriums (NV_INT32 num) {
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  assert (num >= 0 && num < (NV_INT32)hd.pub.constituents);
  return hd.equilibrium[num];
}


/*****************************************************************************\

    Function        get_node_factor - gets the node factor value for
                    constituent number "num" and year "year"

    Synopsis        get_node_factor (num, year);

                    NV_INT32 num            constituent number
                    NV_INT32 year           year

    Returns         NV_FLOAT32              node factor

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_FLOAT32 get_node_factor (NV_INT32 num, NV_INT32 year)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  assert (num >= 0 && num < (NV_INT32)hd.pub.constituents && year >= 0 && year < (NV_INT32)hd.pub.number_of_years);
  return hd.node_factor[num][year];
}


/*****************************************************************************\
  DWF 2004-10-04
\*****************************************************************************/
NV_FLOAT32 *get_node_factors (NV_INT32 num) {
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
  assert (num >= 0 && num < (NV_INT32)hd.pub.constituents);
  return hd.node_factor[num];
}


/*****************************************************************************\

    Function        get_partial_tide_record - gets "header" portion of record
                    "num" from the index that is stored in memory.  This is
                    way faster than reading it again and we have to read it
                    to set up the index.  This costs a bit in terms of
                    memory but most applications use this data far more than
                    the rest of the record.

    Synopsis        get_partial_tide_record (num, rec);

                    NV_INT32 num              record number
                    TIDE_STATION_HEADER *rec  header portion of the record

    Returns         NV_BOOL                   NVTrue if successful

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_BOOL get_partial_tide_record (NV_INT32 num, TIDE_STATION_HEADER *rec)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return NVFalse;
  }

    if (num < 0 || num >= (NV_INT32)hd.pub.number_of_records) return (NVFalse);

    assert (rec);

    rec->record_number = num;
    rec->record_size = tindex[num].record_size;
    rec->record_type = tindex[num].record_type;
    rec->latitude = (NV_FLOAT64) tindex[num].lat / hd.latitude_scale;
    rec->longitude = (NV_FLOAT64) tindex[num].lon / hd.longitude_scale;
    rec->reference_station = tindex[num].reference_station;
    rec->tzfile = tindex[num].tzfile;
    strcpy (rec->name, tindex[num].name);

    current_index = num;

    return (NVTrue);
}


/*****************************************************************************\

    Function        get_next_partial_tide_record - gets "header" portion of
                    the next record from the index that is stored in memory.

    Synopsis        get_next_partial_tide_record (rec);

                    TIDE_STATION_HEADER *rec  header portion of the record

    Returns         NV_INT32                  record number or -1 on failure

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 get_next_partial_tide_record (TIDE_STATION_HEADER *rec)
{
    if (!get_partial_tide_record (current_index + 1, rec)) return (-1);

    return (current_index);
}


/*****************************************************************************\

    Function        get_nearest_partial_tide_record - gets "header" portion of
                    the record closest geographically to the input position.

    Synopsis        get_nearest_partial_tide_record (lat, lon, rec);

                    NV_FLOAT64 lat            latitude
                    NV_FLOAT64 lon            longitude
                    TIDE_STATION_HEADER *rec  header portion of the record

    Returns         NV_INT32                  record number or -1 on failure

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 get_nearest_partial_tide_record (NV_FLOAT64 lat, NV_FLOAT64 lon,
TIDE_STATION_HEADER *rec)
{
    NV_FLOAT64           diff, min_diff, lt, ln;
    NV_U_INT32             i, shortest = 0;

    min_diff = 999999999.9;
    for (i = 0 ; i < hd.pub.number_of_records ; ++i)
    {
        lt = (NV_FLOAT64) tindex[i].lat / hd.latitude_scale;
        ln = (NV_FLOAT64) tindex[i].lon / hd.longitude_scale;

        diff = sqrt ((lat - lt) * (lat - lt) + (lon - ln) * (lon - ln));

        if (diff < min_diff)
        {
            min_diff = diff;
            shortest = i;
        }
    }

    if (!get_partial_tide_record (shortest, rec)) return (-1);
    return (shortest);
}


/*****************************************************************************\

    Function        get_time - converts a time string in +/-HH:MM form to an
                    integer in +/-HHMM form

    Synopsis        get_time (string);

                    NV_CHAR *string         time string

    Returns         NV_INT32                time

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 get_time (NV_CHAR *string)
{
    NV_INT32        hour, minute, hhmm;

    assert (string);
    sscanf (string, "%d:%d", &hour, &minute);


    /*  Trying to deal with negative 0 (-00:45).  */

    if (string[0] == '-')
    {
        if (hour < 0) hour = -hour;

        hhmm = -(hour * 100 + minute);
    }
    else
    {
        hhmm = hour * 100 + minute;
    }

    return (hhmm);
}


/*****************************************************************************\

    Function        ret_time - converts a time value in +/-HHMM form to a
                    time string in +/-HH:MM form

    Synopsis        ret_time (time);

                    NV_INT32                time

    Returns         NV_CHAR *               time string

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_CHAR *ret_time (NV_INT32 time)
{
    NV_INT32          hour, minute;
    static NV_CHAR    tname[10];

    hour = abs (time) / 100;
    assert (hour < 100000); /* 9 chars: +99999:99 */
    minute = abs (time) % 100;

    if (time < 0)
    {
        sprintf (tname, "-%02d:%02d", hour, minute);
    }
    else
    {
        sprintf (tname, "+%02d:%02d", hour, minute);
    }

    return tname;
}


/*****************************************************************************\
  DWF 2004-10-04
\*****************************************************************************/
NV_CHAR *ret_time_neat (NV_INT32 time)
{
    NV_INT32          hour, minute;
    static NV_CHAR    tname[10];

    hour = abs (time) / 100;
    assert (hour < 100000); /* 9 chars: +99999:99 */
    minute = abs (time) % 100;

    if (time < 0)
      sprintf (tname, "-%d:%02d", hour, minute);
    else if (time > 0)
      sprintf (tname, "+%d:%02d", hour, minute);
    else
      strcpy (tname, "0:00");

    return tname;
}


/*****************************************************************************\
  DWF 2004-10-04
\*****************************************************************************/
NV_CHAR *ret_date (NV_U_INT32 date) {
  static NV_CHAR tname[30];
  if (!date)
    strcpy (tname, "NULL");
  else {
    unsigned y, m, d;
    y = date / 10000;
    date %= 10000;
    m = date / 100;
    d = date % 100;
    sprintf (tname, "%4u-%02u-%02u", y, m, d);
  }
  return tname;
}


/*****************************************************************************\

    Function        get_tide_db_header - gets the public portion of the tide
                    database header

    Synopsis        get_tide_db_header ();

    Returns         DB_HEADER_PUBLIC        public tide header

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

DB_HEADER_PUBLIC get_tide_db_header ()
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit(-1);
  }
    return (hd.pub);
}


/*****************************************************************************\
   DWF 2004-09-30
   Prevent buffer overflows for MONOLOGUE_LENGTH strings.
\*****************************************************************************/
static void boundscheck_monologue (NV_CHAR *string) {
  assert (string);
  if (strlen(string) >= MONOLOGUE_LENGTH) {
    fprintf (stderr, "libtcd fatal error:  static buffer size exceeded\n");
    fprintf (stderr, "Buffer is size MONOLOGUE_LENGTH (%u)\n",
             MONOLOGUE_LENGTH);
    fprintf (stderr, "String is length %lu\n", strlen(string));
    fprintf (stderr, "The offending string is:\n%s\n", string);
    exit (-1);
  }
}


/*****************************************************************************\
   DWF 2004-09-30
   Prevent buffer overflows for ONELINER_LENGTH strings.
\*****************************************************************************/
static void boundscheck_oneliner (NV_CHAR *string) {
  assert (string);
  if (strlen(string) >= ONELINER_LENGTH) {
    fprintf (stderr, "libtcd fatal error:  static buffer size exceeded\n");
    fprintf (stderr, "Buffer is size ONELINER_LENGTH (%u)\n",
             ONELINER_LENGTH);
    fprintf (stderr, "String is length %lu\n", strlen(string));
    fprintf (stderr, "The offending string is:\n%s\n", string);
    exit (-1);
  }
}


/*****************************************************************************\

    Function        clip_string - removes leading and trailing spaces from
                    search strings.

    Synopsis        clip_string (string);

                    NV_CHAR *string         search string

    Returns         NV_CHAR *               clipped string

    Author          Jan C. Depner
    Date            09/16/02

    See libtcd.html for changelog.

\*****************************************************************************/

static NV_CHAR *clip_string (NV_CHAR *string)
{
  static NV_CHAR        new_string[MONOLOGUE_LENGTH];
  NV_INT32              i, l, start = -1, end = -1;

  boundscheck_monologue (string);
  new_string[0] = '\0';

  l = (int)strlen(string);
  if (l) {
    for (i=0; i<l; ++i) {
      if (string[i] != ' ') {
        start = i;
        break;
      }
    }
    for (i=l-1; i >= start; --i) {
      if (string[i] != ' ' && string[i] != 10 && string[i] != 13) {
        end = i;
        break;
      }
    }
    if (start > -1 && end > -1 && end >= start) {
      strncpy (new_string, string+start, end-start+1);
      new_string[end-start+1] = '\0';
    }
  }
  return new_string;
}


/*****************************************************************************\

    Function        search_station - returns record numbers of all stations
                    that have the string "string" anywhere in the station
                    name.  This search is case insensitive.  When no more
                    records are found it returns -1;

    Synopsis        search_station (string);

                    NV_CHAR *string         search string

    Returns         NV_INT32                record number or -1 when no more
                                            matches

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 search_station (NV_CHAR *string)
{
    static NV_CHAR        last_search[ONELINER_LENGTH];
    static NV_U_INT32     j=0;
    NV_U_INT32            i;
    NV_CHAR               name[ONELINER_LENGTH], search[ONELINER_LENGTH];

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

    boundscheck_oneliner (string);

    for (i = 0 ; i < strlen(string) + 1 ; ++i)
        search[i] = tolower (string[i]);

    if (strcmp (search, last_search)) j = 0;

    strcpy (last_search, search);

    while (j < hd.pub.number_of_records)
    {
        for (i = 0 ; i < strlen(tindex[j].name) + 1 ; ++i)
            name[i] = tolower (tindex[j].name[i]);

        ++j;
        if (strstr (name, search))
          return (j - 1);
    }

    j = 0;
    return -1;
}


/*****************************************************************************\

    Function        find_station - finds the record number of the station
                    that has name "name"

    Synopsis        find_station (name);

                    NV_CHAR *name           station name

    Returns         NV_INT32                record number

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 find_station (NV_CHAR *name)
{
    NV_U_INT32              i;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

    assert (name);
    for (i = 0 ; i < hd.pub.number_of_records ; ++i)
    {
        if (!strcmp (name, tindex[i].name)) return (i);
    }

    return (-1);
}


/*****************************************************************************\

    Function        find_tzfile - gets the timezone number (index into
                    tzfile array) given the tzfile name

    Synopsis        find_tzfile (name);

                    NV_CHAR *name          tzfile name

    Returns         NV_INT32                tzfile number

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 find_tzfile (NV_CHAR *name)
{
    NV_INT32   j;
    NV_U_INT32 i;
    NV_CHAR     *temp;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

    temp = clip_string(name);

    j = -1;
    for (i = 0 ; i < hd.pub.tzfiles ; ++i)
    {
        if (!strcmp (temp, get_tzfile (i)))
        {
            j = i;
            break;
        }
    }

    return (j);
}


/*****************************************************************************\

    Function        find_country - gets the timezone number (index into
                    country array) given the country name

    Synopsis        find_country (name);

                    NV_CHAR *name          country name

    Returns         NV_INT32                country number

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 find_country (NV_CHAR *name)
{
    NV_INT32    j;
    NV_U_INT32  i;
    NV_CHAR     *temp;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

    temp = clip_string(name);

    j = -1;
    for (i = 0 ; i < hd.pub.countries ; ++i)
    {
        if (!strcmp (temp, get_country (i)))
        {
            j = i;
            break;
        }
    }

    return (j);
}


/*****************************************************************************\

    Function        find_level_units - gets the index into the level_units
                    array given the level units name

    Synopsis        find_level_units (name);

                    NV_CHAR *name          units name (ex. "meters")

    Returns         NV_INT32                units number

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 find_level_units (NV_CHAR *name)
{
    NV_INT32    j;
    NV_U_INT32  i;
    NV_CHAR     *temp;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

    temp = clip_string(name);

    j = -1;
    for (i = 0 ; i < hd.pub.level_unit_types ; ++i)
    {
        if (!strcmp (get_level_units (i), temp))
        {
            j = i;
            break;
        }
    }

    return (j);
}


/*****************************************************************************\

    Function        find_dir_units - gets the index into the dir_units
                    array given the direction units name

    Synopsis        find_dir_units (name);

                    NV_CHAR *name          units name (ex. "degrees true")

    Returns         NV_INT32                units number

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 find_dir_units (NV_CHAR *name)
{
    NV_INT32    j;
    NV_U_INT32  i;
    NV_CHAR     *temp;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

    temp = clip_string(name);

    j = -1;
    for (i = 0 ; i < hd.pub.dir_unit_types ; ++i)
    {
        if (!strcmp (get_dir_units (i), temp))
        {
            j = i;
            break;
        }
    }

    return (j);
}


/*****************************************************************************\

    Function        find_pedigree - gets the index into the pedigree array
                    given the pedigree name

    Synopsis        find_pedigree (name);

                    NV_CHAR *name          pedigree name

    Returns         NV_INT32                pedigree number

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

#ifdef COMPAT114
NV_INT32 find_pedigree (NV_CHAR *name) {
  return 0;
}
#endif


/*****************************************************************************\

    Function        find_datum - gets the index into the datum array given the
                    datum name

    Synopsis        find_datum (name);

                    NV_CHAR *name          datum name

    Returns         NV_INT32                datum number

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 find_datum (NV_CHAR *name)
{
    NV_INT32    j;
    NV_U_INT32  i;
    NV_CHAR     *temp;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

    temp = clip_string(name);

    j = -1;
    for (i = 0 ; i < hd.pub.datum_types ; ++i)
    {
        if (!strcmp (get_datum (i), temp))
        {
            j = i;
            break;
        }
    }

    return (j);
}


/*****************************************************************************\
  DWF 2004-10-14
\*****************************************************************************/
NV_INT32 find_legalese (NV_CHAR *name)
{
  NV_INT32    j;
  NV_U_INT32  i;
  NV_CHAR     *temp;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

  temp = clip_string(name);

  j = -1;
  for (i = 0 ; i < hd.pub.legaleses ; ++i)
  {
    if (!strcmp (get_legalese (i), temp))
    {
      j = i;
      break;
    }
  }

  return (j);
}


/*****************************************************************************\

    Function        find_constituent - gets the index into the constituent
                    arrays for the named constituent.

    Synopsis        find_constituent (name);

                    NV_CHAR *name           constituent name (ex. M2)

    Returns         NV_INT32                index into constituent arrays or -1
                                            on failure

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 find_constituent (NV_CHAR *name)
{
    NV_U_INT32               i;
    NV_CHAR     *temp;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

    temp = clip_string(name);

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
      if (!strcmp (get_constituent (i), temp)) return (i);
    }

    return (-1);
}


/*****************************************************************************\

    Function        find_restriction - gets the index into the restriction
                    array given the restriction name

    Synopsis        find_restriction (name);

                    NV_CHAR *name          restriction name

    Returns         NV_INT32                restriction number

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 find_restriction (NV_CHAR *name)
{
    NV_INT32    j;
    NV_U_INT32  i;
    NV_CHAR     *temp;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

    temp = clip_string(name);

    j = -1;
    for (i = 0 ; i < hd.pub.restriction_types ; ++i)
    {
        if (!strcmp (get_restriction (i), temp))
        {
            j = i;
            break;
        }
    }
    return (j);
}


/*****************************************************************************\

    Function        set_speed - sets the speed value for constituent "num"

    Synopsis        set_speed (num, value);

                    NV_INT32 num            constituent number
                    NV_FLOAT64 value        speed value

    Returns         void

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

void set_speed (NV_INT32 num, NV_FLOAT64 value)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }
  write_protect();
  assert (num >= 0 && num < (NV_INT32)hd.pub.constituents);
  if (value < 0.0) {
    fprintf (stderr, "libtcd set_speed: somebody tried to set a negative speed (%f)\n", value);
    exit (-1);
  }
  hd.speed[num] = value;
  modified = NVTrue;
}


/*****************************************************************************\

    Function        set_equilibrium - sets the equilibrium argument for
                    constituent "num" and year "year"

    Synopsis        set_equilibrium (num, year, value);

                    NV_INT32 num            constituent number
                    NV_INT32 year           year
                    NV_FLOAT64 value        equilibrium argument

    Returns         void

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

void set_equilibrium (NV_INT32 num, NV_INT32 year, NV_FLOAT32 value)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }
  write_protect();
  assert (num >= 0 && num < (NV_INT32)hd.pub.constituents && year >= 0 && year < (NV_INT32)hd.pub.number_of_years);
  hd.equilibrium[num][year] = value;
  modified = NVTrue;
}


/*****************************************************************************\

    Function        set_node_factor - sets the node factor for constituent
                    "num" and year "year"

    Synopsis        set_node_factor (num, year, value);

                    NV_INT32 num            constituent number
                    NV_INT32 year           year
                    NV_FLOAT64 value        node factor

    Returns         void

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

void set_node_factor (NV_INT32 num, NV_INT32 year, NV_FLOAT32 value)
{
  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }
  write_protect();
  assert (num >= 0 && num < (NV_INT32)hd.pub.constituents && year >= 0 && year < (NV_INT32)hd.pub.number_of_years);
  if (value <= 0.0) {
    fprintf (stderr, "libtcd set_node_factor: somebody tried to set a negative or zero node factor (%f)\n", value);
    exit (-1);
  }
  hd.node_factor[num][year] = value;
  modified = NVTrue;
}


/*****************************************************************************\

    Function        add_pedigree - adds a new pedigree to the database

    Synopsis        add_pedigree (name, db);

                    NV_CHAR *name          new pedigree string
                    DB_HEADER_PUBLIC *db    modified header

    Returns         NV_INT32                new pedigree index

    Author          Jan C. Depner
    Date            09/20/02

    See libtcd.html for changelog.

\*****************************************************************************/

#ifdef COMPAT114
NV_INT32 add_pedigree (NV_CHAR *name, DB_HEADER_PUBLIC *db) {
  return 0;
}
#endif


/*****************************************************************************\

    Function        add_tzfile - adds a new tzfile to the database

    Synopsis        add_tzfile (name, db);

                    NV_CHAR *name          new tzfile string
                    DB_HEADER_PUBLIC *db    modified header

    Returns         NV_INT32                new tzfile index

    Author          Jan C. Depner
    Date            09/20/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 add_tzfile (NV_CHAR *name, DB_HEADER_PUBLIC *db)
{
    NV_CHAR *c_name;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }
  write_protect();

  assert (name);
  if (strlen(name) + 1 > hd.tzfile_size) {
    fprintf (stderr, "libtcd error: tzfile exceeds size limit (%u).\n",
             hd.tzfile_size);
    fprintf (stderr, "The offending input is: %s\n", name);
    exit (-1);
  }

    if (hd.pub.tzfiles == hd.max_tzfiles)
    {
        fprintf (stderr,
            "You have exceeded the maximum number of tzfile types!\n");
        fprintf (stderr,
            "You cannot add any new tzfile types.\n");
        fprintf (stderr,
            "Modify the DEFAULT_TZFILE_BITS and rebuild the database.\n");
        exit (-1);
    }

    c_name = clip_string (name);

    hd.tzfile[hd.pub.tzfiles] = (NV_CHAR *) calloc (strlen (c_name) + 1,
        sizeof (NV_CHAR));

    if (hd.tzfile[hd.pub.tzfiles] == NULL)
    {
        perror ("Allocating new tzfile string");
        exit (-1);
    }

    strcpy (hd.tzfile[hd.pub.tzfiles++], c_name);
    if (db)
      *db = hd.pub;
    modified = NVTrue;
    return (hd.pub.tzfiles - 1);
}


/*****************************************************************************\

    Function        add_country - adds a new country to the database

    Synopsis        add_country (name, db);

                    NV_CHAR *name          new country string
                    DB_HEADER_PUBLIC *db    modified header

    Returns         NV_INT32                new country index

    Author          Jan C. Depner
    Date            09/20/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 add_country (NV_CHAR *name, DB_HEADER_PUBLIC *db)
{
    NV_CHAR *c_name;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }
  write_protect();

  assert (name);
  if (strlen(name) + 1 > hd.country_size) {
    fprintf (stderr, "libtcd error: country exceeds size limit (%u).\n",
             hd.country_size);
    fprintf (stderr, "The offending input is: %s\n", name);
    exit (-1);
  }

    if (hd.pub.countries == hd.max_countries)
    {
        fprintf (stderr,
            "You have exceeded the maximum number of country names!\n");
        fprintf (stderr,
            "You cannot add any new country names.\n");
        fprintf (stderr,
            "Modify the DEFAULT_COUNTRY_BITS and rebuild the database.\n");
        exit (-1);
    }

    c_name = clip_string (name);

    hd.country[hd.pub.countries] = (NV_CHAR *) calloc (strlen (c_name) + 1,
        sizeof (NV_CHAR));

    if (hd.country[hd.pub.countries] == NULL)
    {
        perror ("Allocating new country string");
        exit (-1);
    }

    strcpy (hd.country[hd.pub.countries++], c_name);
    if (db)
      *db = hd.pub;
    modified = NVTrue;
    return (hd.pub.countries - 1);
}


/*****************************************************************************\

    Function        add_datum - adds a new datum to the database

    Synopsis        add_datum (name, db);

                    NV_CHAR *name          new datum string
                    DB_HEADER_PUBLIC *db    modified header

    Returns         NV_INT32                new datum index

    Author          Jan C. Depner
    Date            09/20/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 add_datum (NV_CHAR *name, DB_HEADER_PUBLIC *db)
{
    NV_CHAR *c_name;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }
  write_protect();

  assert (name);
  if (strlen(name) + 1 > hd.datum_size) {
    fprintf (stderr, "libtcd error: datum exceeds size limit (%u).\n",
             hd.datum_size);
    fprintf (stderr, "The offending input is: %s\n", name);
    exit (-1);
  }

    if (hd.pub.datum_types == hd.max_datum_types)
    {
        fprintf (stderr,
            "You have exceeded the maximum number of datum types!\n");
        fprintf (stderr,
            "You cannot add any new datum types.\n");
        fprintf (stderr,
            "Modify the DEFAULT_DATUM_BITS and rebuild the database.\n");
        exit (-1);
    }

    c_name = clip_string (name);

    hd.datum[hd.pub.datum_types] = (NV_CHAR *) calloc (strlen (c_name) + 1,
        sizeof (NV_CHAR));

    if (hd.datum[hd.pub.datum_types] == NULL)
    {
        perror ("Allocating new datum string");
        exit (-1);
    }

    strcpy (hd.datum[hd.pub.datum_types++], c_name);
    if (db)
      *db = hd.pub;
    modified = NVTrue;
    return (hd.pub.datum_types - 1);
}


/*****************************************************************************\
  DWF 2004-10-14
\*****************************************************************************/
NV_INT32 add_legalese (NV_CHAR *name, DB_HEADER_PUBLIC *db)
{
    NV_CHAR *c_name;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }
  write_protect();

  assert (name);
  if (strlen(name) + 1 > hd.legalese_size) {
    fprintf (stderr, "libtcd error: legalese exceeds size limit (%u).\n",
             hd.legalese_size);
    fprintf (stderr, "The offending input is: %s\n", name);
    exit (-1);
  }

    if (hd.pub.legaleses == hd.max_legaleses)
    {
        fprintf (stderr,
            "You have exceeded the maximum number of legaleses!\n");
        fprintf (stderr,
            "You cannot add any new legaleses.\n");
        fprintf (stderr,
            "Modify the DEFAULT_LEGALESE_BITS and rebuild the database.\n");
        exit (-1);
    }

    c_name = clip_string (name);

    hd.legalese[hd.pub.legaleses] = (NV_CHAR *) calloc (strlen (c_name) + 1,
        sizeof (NV_CHAR));

    if (hd.legalese[hd.pub.legaleses] == NULL)
    {
        perror ("Allocating new legalese string");
        exit (-1);
    }

    strcpy (hd.legalese[hd.pub.legaleses++], c_name);
    if (db)
      *db = hd.pub;
    modified = NVTrue;
    return (hd.pub.legaleses - 1);
}


/*****************************************************************************\

    Function        add_restriction - adds a new restriction to the database

    Synopsis        add_restriction (name, db);

                    NV_CHAR *name          new restriction string
                    DB_HEADER_PUBLIC *db    modified header

    Returns         NV_INT32                new restriction index

    Author          Jan C. Depner
    Date            09/20/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 add_restriction (NV_CHAR *name, DB_HEADER_PUBLIC *db)
{
    NV_CHAR *c_name;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }
  write_protect();

  assert (name);
  if (strlen(name) + 1 > hd.restriction_size) {
    fprintf (stderr, "libtcd error: restriction exceeds size limit (%u).\n",
             hd.restriction_size);
    fprintf (stderr, "The offending input is: %s\n", name);
    exit (-1);
  }

    if (hd.pub.restriction_types == hd.max_restriction_types)
    {
        fprintf (stderr,
            "You have exceeded the maximum number of restriction types!\n");
        fprintf (stderr,
            "You cannot add any new restriction types.\n");
        fprintf (stderr,
            "Modify the DEFAULT_RESTRICTION_BITS and rebuild the database.\n");
        exit (-1);
    }

    c_name = clip_string (name);

    hd.restriction[hd.pub.restriction_types] =
        (NV_CHAR *) calloc (strlen (c_name) + 1, sizeof (NV_CHAR));

    if (hd.restriction[hd.pub.restriction_types] == NULL)
    {
        perror ("Allocating new restriction string");
        exit (-1);
    }

    strcpy (hd.restriction[hd.pub.restriction_types++], c_name);
    if (db)
      *db = hd.pub;
    modified = NVTrue;
    return (hd.pub.restriction_types - 1);
}


/*****************************************************************************\
  DWF 2004-10-04
\*****************************************************************************/
NV_INT32 find_or_add_restriction (NV_CHAR *name, DB_HEADER_PUBLIC *db) {
  NV_INT32 ret;
  ret = find_restriction (name);
  if (ret < 0)
    ret = add_restriction (name, db);
  assert (ret >= 0);
  return ret;
}


/*****************************************************************************\
  DWF 2004-10-04
\*****************************************************************************/
NV_INT32 find_or_add_tzfile (NV_CHAR *name, DB_HEADER_PUBLIC *db) {
  NV_INT32 ret;
  ret = find_tzfile (name);
  if (ret < 0)
    ret = add_tzfile (name, db);
  assert (ret >= 0);
  return ret;
}


/*****************************************************************************\
  DWF 2004-10-04
\*****************************************************************************/
NV_INT32 find_or_add_country (NV_CHAR *name, DB_HEADER_PUBLIC *db) {
  NV_INT32 ret;
  ret = find_country (name);
  if (ret < 0)
    ret = add_country (name, db);
  assert (ret >= 0);
  return ret;
}


/*****************************************************************************\
  DWF 2004-10-04
\*****************************************************************************/
NV_INT32 find_or_add_datum (NV_CHAR *name, DB_HEADER_PUBLIC *db) {
  NV_INT32 ret;
  ret = find_datum (name);
  if (ret < 0)
    ret = add_datum (name, db);
  assert (ret >= 0);
  return ret;
}


/*****************************************************************************\
  DWF 2004-10-14
\*****************************************************************************/
NV_INT32 find_or_add_legalese (NV_CHAR *name, DB_HEADER_PUBLIC *db) {
  NV_INT32 ret;
  ret = find_legalese (name);
  if (ret < 0)
    ret = add_legalese (name, db);
  assert (ret >= 0);
  return ret;
}


/*****************************************************************************\

    Function        check_simple - checks tide record to see if it is a
                    "simple" subordinate station.

    Synopsis        check_simple (rec);

                    TIDE_RECORD rec         tide record

    Returns         NV_BOOL                 NVTrue if "simple"

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

    "Simplified" type 2 records were done away with 2003-03-27 per the
    discussion in http://www.flaterco.com/xtide/tcd_notes.html.  This
    function is now of interest only in restore_tide_db, which uses it
    to determine which XML format to output.  Deprecated here, moved
    to restore_tide_db.

\*****************************************************************************/

#ifdef COMPAT114
NV_BOOL check_simple (TIDE_RECORD rec)
{
  if (rec.max_time_add       == rec.min_time_add        &&
      rec.max_level_add      == rec.min_level_add       &&
      rec.max_level_multiply == rec.min_level_multiply  &&
      rec.max_avg_level == 0   &&
      rec.min_avg_level == 0   &&
      rec.max_direction == 361 &&
      rec.min_direction == 361 &&
      rec.flood_begins  == NULLSLACKOFFSET &&
      rec.ebb_begins    == NULLSLACKOFFSET)
    return (NVTrue);

    return (NVFalse);
}
#endif


/*****************************************************************************\

    Function        header_checksum - compute the checksum for the ASCII
                    portion of the database header

    Synopsis        header_checksum ();

    Returns         NV_U_INT32              checksum value

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

static NV_U_INT32 header_checksum ()
{
    NV_U_INT32          checksum, i, save_pos;
    NV_U_BYTE           *buf;
    NV_U_INT32          crc_table[256] =
      {0x00000000,0x77073096,0xEE0E612C,0x990951BA,0x076DC419,0x706AF48F,
       0xE963A535,0x9E6495A3,0x0EDB8832,0x79DCB8A4,0xE0D5E91E,0x97D2D988,
       0x09B64C2B,0x7EB17CBD,0xE7B82D07,0x90BF1D91,0x1DB71064,0x6AB020F2,
       0xF3B97148,0x84BE41DE,0x1ADAD47D,0x6DDDE4EB,0xF4D4B551,0x83D385C7,
       0x136C9856,0x646BA8C0,0xFD62F97A,0x8A65C9EC,0x14015C4F,0x63066CD9,
       0xFA0F3D63,0x8D080DF5,0x3B6E20C8,0x4C69105E,0xD56041E4,0xA2677172,
       0x3C03E4D1,0x4B04D447,0xD20D85FD,0xA50AB56B,0x35B5A8FA,0x42B2986C,
       0xDBBBC9D6,0xACBCF940,0x32D86CE3,0x45DF5C75,0xDCD60DCF,0xABD13D59,
       0x26D930AC,0x51DE003A,0xC8D75180,0xBFD06116,0x21B4F4B5,0x56B3C423,
       0xCFBA9599,0xB8BDA50F,0x2802B89E,0x5F058808,0xC60CD9B2,0xB10BE924,
       0x2F6F7C87,0x58684C11,0xC1611DAB,0xB6662D3D,0x76DC4190,0x01DB7106,
       0x98D220BC,0xEFD5102A,0x71B18589,0x06B6B51F,0x9FBFE4A5,0xE8B8D433,
       0x7807C9A2,0x0F00F934,0x9609A88E,0xE10E9818,0x7F6A0DBB,0x086D3D2D,
       0x91646C97,0xE6635C01,0x6B6B51F4,0x1C6C6162,0x856530D8,0xF262004E,
       0x6C0695ED,0x1B01A57B,0x8208F4C1,0xF50FC457,0x65B0D9C6,0x12B7E950,
       0x8BBEB8EA,0xFCB9887C,0x62DD1DDF,0x15DA2D49,0x8CD37CF3,0xFBD44C65,
       0x4DB26158,0x3AB551CE,0xA3BC0074,0xD4BB30E2,0x4ADFA541,0x3DD895D7,
       0xA4D1C46D,0xD3D6F4FB,0x4369E96A,0x346ED9FC,0xAD678846,0xDA60B8D0,
       0x44042D73,0x33031DE5,0xAA0A4C5F,0xDD0D7CC9,0x5005713C,0x270241AA,
       0xBE0B1010,0xC90C2086,0x5768B525,0x206F85B3,0xB966D409,0xCE61E49F,
       0x5EDEF90E,0x29D9C998,0xB0D09822,0xC7D7A8B4,0x59B33D17,0x2EB40D81,
       0xB7BD5C3B,0xC0BA6CAD,0xEDB88320,0x9ABFB3B6,0x03B6E20C,0x74B1D29A,
       0xEAD54739,0x9DD277AF,0x04DB2615,0x73DC1683,0xE3630B12,0x94643B84,
       0x0D6D6A3E,0x7A6A5AA8,0xE40ECF0B,0x9309FF9D,0x0A00AE27,0x7D079EB1,
       0xF00F9344,0x8708A3D2,0x1E01F268,0x6906C2FE,0xF762575D,0x806567CB,
       0x196C3671,0x6E6B06E7,0xFED41B76,0x89D32BE0,0x10DA7A5A,0x67DD4ACC,
       0xF9B9DF6F,0x8EBEEFF9,0x17B7BE43,0x60B08ED5,0xD6D6A3E8,0xA1D1937E,
       0x38D8C2C4,0x4FDFF252,0xD1BB67F1,0xA6BC5767,0x3FB506DD,0x48B2364B,
       0xD80D2BDA,0xAF0A1B4C,0x36034AF6,0x41047A60,0xDF60EFC3,0xA867DF55,
       0x316E8EEF,0x4669BE79,0xCB61B38C,0xBC66831A,0x256FD2A0,0x5268E236,
       0xCC0C7795,0xBB0B4703,0x220216B9,0x5505262F,0xC5BA3BBE,0xB2BD0B28,
       0x2BB45A92,0x5CB36A04,0xC2D7FFA7,0xB5D0CF31,0x2CD99E8B,0x5BDEAE1D,
       0x9B64C2B0,0xEC63F226,0x756AA39C,0x026D930A,0x9C0906A9,0xEB0E363F,
       0x72076785,0x05005713,0x95BF4A82,0xE2B87A14,0x7BB12BAE,0x0CB61B38,
       0x92D28E9B,0xE5D5BE0D,0x7CDCEFB7,0x0BDBDF21,0x86D3D2D4,0xF1D4E242,
       0x68DDB3F8,0x1FDA836E,0x81BE16CD,0xF6B9265B,0x6FB077E1,0x18B74777,
       0x88085AE6,0xFF0F6A70,0x66063BCA,0x11010B5C,0x8F659EFF,0xF862AE69,
       0x616BFFD3,0x166CCF45,0xA00AE278,0xD70DD2EE,0x4E048354,0x3903B3C2,
       0xA7672661,0xD06016F7,0x4969474D,0x3E6E77DB,0xAED16A4A,0xD9D65ADC,
       0x40DF0B66,0x37D83BF0,0xA9BCAE53,0xDEBB9EC5,0x47B2CF7F,0x30B5FFE9,
       0xBDBDF21C,0xCABAC28A,0x53B39330,0x24B4A3A6,0xBAD03605,0xCDD70693,
       0x54DE5729,0x23D967BF,0xB3667A2E,0xC4614AB8,0x5D681B02,0x2A6F2B94,
       0xB40BBE37,0xC30C8EA1,0x5A05DF1B,0x2D02EF8D};

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }

    save_pos = (NV_U_INT32)ftell (fp);

    fseek (fp, 0, SEEK_SET);

    if ((buf = (NV_U_BYTE *) calloc (hd.header_size, sizeof (NV_U_BYTE))) ==
        NULL)
    {
        perror ("Allocating checksum buffer");
        exit (-1);
    }

    checksum = ~0;

    assert (hd.header_size > 0);
    chk_fread (buf, hd.header_size, 1, fp);
    for (i = 0 ; i < (NV_U_INT32)hd.header_size ; ++i)
    {
        checksum = crc_table[(checksum ^ buf[i]) & 0xff] ^ (checksum >> 8);
    }
    checksum ^= ~0;

    free (buf);

    fseek (fp, save_pos, SEEK_SET);

    return (checksum);
}


/*****************************************************************************\

    Function        old_header_checksum - compute the old-style checksum for 
                    the ASCII portion of the database header just in case this
                    is a pre 1.02 file.

    Synopsis        old_header_checksum ();

    Returns         NV_U_INT32              checksum value

    Author          Jan C. Depner
    Date            11/15/02

\*****************************************************************************/

#ifdef COMPAT114
static NV_U_INT32 old_header_checksum ()
{
    NV_U_INT32          checksum, i, save_pos;
    NV_U_BYTE           *buf;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }

    save_pos = ftell (fp);

    checksum = 0;

    fseek (fp, 0, SEEK_SET);

    if ((buf = (NV_U_BYTE *) calloc (hd.header_size, sizeof (NV_U_BYTE))) == 
        NULL)
    {
        perror ("Allocating checksum buffer");
        exit (-1);
    }

    chk_fread (buf, hd.header_size, 1, fp);

    for (i = 0 ; i < hd.header_size ; ++i) checksum += buf[i];

    free (buf);

    fseek (fp, save_pos, SEEK_SET);

    return (checksum);
}
#endif


/*****************************************************************************\
   DWF 2004-10-01
   Get current time in preferred format.
\*****************************************************************************/
static NV_CHAR *curtime () {
  static NV_CHAR buf[ONELINER_LENGTH];
  time_t t = time(NULL);
  require (strftime (buf, ONELINER_LENGTH, "%Y-%m-%d %H:%M %Z", localtime(&t)) > 0);
  return buf;
}


/*****************************************************************************\
   DWF 2004-10-15
   Calculate bytes for number of bits.
\*****************************************************************************/
static NV_U_INT32 bits2bytes (NV_U_INT32 nbits) {
  if (nbits % 8)
    return nbits / 8 + 1;
  return nbits / 8;
}


/*****************************************************************************\

    Function        write_tide_db_header - writes the database header to the
                    file

    Synopsis        write_tide_db_header ();

    Returns         void

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

static void write_tide_db_header ()
{
    NV_U_INT32          i, size, pos;
    NV_INT32            start, temp_int;
    static NV_CHAR      zero = 0;
    NV_U_BYTE           *buf, checksum_c[4];

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }
  write_protect();

    fseek (fp, 0, SEEK_SET);

    fprintf (fp, "[VERSION] = %s\n", LIBTCD_VERSION);
    fprintf (fp, "[MAJOR REV] = %u\n", LIBTCD_MAJOR_REV);
    fprintf (fp, "[MINOR REV] = %u\n", LIBTCD_MINOR_REV);

    fprintf (fp, "[LAST MODIFIED] = %s\n", curtime());

    fprintf (fp, "[HEADER SIZE] = %u\n", hd.header_size);
    fprintf (fp, "[NUMBER OF RECORDS] = %u\n", hd.pub.number_of_records);

    fprintf (fp, "[START YEAR] = %d\n", hd.pub.start_year);
    fprintf (fp, "[NUMBER OF YEARS] = %u\n", hd.pub.number_of_years);

    fprintf (fp, "[SPEED BITS] = %u\n", hd.speed_bits);
    fprintf (fp, "[SPEED SCALE] = %u\n", hd.speed_scale);
    fprintf (fp, "[SPEED OFFSET] = %d\n", hd.speed_offset);
    fprintf (fp, "[EQUILIBRIUM BITS] = %u\n", hd.equilibrium_bits);
    fprintf (fp, "[EQUILIBRIUM SCALE] = %u\n", hd.equilibrium_scale);
    fprintf (fp, "[EQUILIBRIUM OFFSET] = %d\n", hd.equilibrium_offset);
    fprintf (fp, "[NODE BITS] = %u\n", hd.node_bits);
    fprintf (fp, "[NODE SCALE] = %u\n", hd.node_scale);
    fprintf (fp, "[NODE OFFSET] = %d\n", hd.node_offset);
    fprintf (fp, "[AMPLITUDE BITS] = %u\n", hd.amplitude_bits);
    fprintf (fp, "[AMPLITUDE SCALE] = %u\n", hd.amplitude_scale);
    fprintf (fp, "[EPOCH BITS] = %u\n", hd.epoch_bits);
    fprintf (fp, "[EPOCH SCALE] = %u\n", hd.epoch_scale);

    fprintf (fp, "[RECORD TYPE BITS] = %u\n", hd.record_type_bits);
    fprintf (fp, "[LATITUDE BITS] = %u\n", hd.latitude_bits);
    fprintf (fp, "[LATITUDE SCALE] = %u\n", hd.latitude_scale);
    fprintf (fp, "[LONGITUDE BITS] = %u\n", hd.longitude_bits);
    fprintf (fp, "[LONGITUDE SCALE] = %u\n", hd.longitude_scale);
    fprintf (fp, "[RECORD SIZE BITS] = %u\n", hd.record_size_bits);

    fprintf (fp, "[STATION BITS] = %u\n", hd.station_bits);

    fprintf (fp, "[DATUM OFFSET BITS] = %u\n", hd.datum_offset_bits);
    fprintf (fp, "[DATUM OFFSET SCALE] = %u\n", hd.datum_offset_scale);
    fprintf (fp, "[DATE BITS] = %u\n", hd.date_bits);
    fprintf (fp, "[MONTHS ON STATION BITS] = %u\n",
             hd.months_on_station_bits);
    fprintf (fp, "[CONFIDENCE VALUE BITS] = %u\n", hd.confidence_value_bits);

    fprintf (fp, "[TIME BITS] = %u\n", hd.time_bits);
    fprintf (fp, "[LEVEL ADD BITS] = %u\n", hd.level_add_bits);
    fprintf (fp, "[LEVEL ADD SCALE] = %u\n", hd.level_add_scale);
    fprintf (fp, "[LEVEL MULTIPLY BITS] = %u\n", hd.level_multiply_bits);
    fprintf (fp, "[LEVEL MULTIPLY SCALE] = %u\n", hd.level_multiply_scale);
    fprintf (fp, "[DIRECTION BITS] = %u\n", hd.direction_bits);

    fprintf (fp, "[LEVEL UNIT BITS] = %u\n", hd.level_unit_bits);
    fprintf (fp, "[LEVEL UNIT TYPES] = %u\n", hd.pub.level_unit_types);
    fprintf (fp, "[LEVEL UNIT SIZE] = %u\n", hd.level_unit_size);

    fprintf (fp, "[DIRECTION UNIT BITS] = %u\n", hd.dir_unit_bits);
    fprintf (fp, "[DIRECTION UNIT TYPES] = %u\n", hd.pub.dir_unit_types);
    fprintf (fp, "[DIRECTION UNIT SIZE] = %u\n", hd.dir_unit_size);

    fprintf (fp, "[RESTRICTION BITS] = %u\n", hd.restriction_bits);
    fprintf (fp, "[RESTRICTION TYPES] = %u\n", hd.pub.restriction_types);
    fprintf (fp, "[RESTRICTION SIZE] = %u\n", hd.restriction_size);

    fprintf (fp, "[DATUM BITS] = %u\n", hd.datum_bits);
    fprintf (fp, "[DATUM TYPES] = %u\n", hd.pub.datum_types);
    fprintf (fp, "[DATUM SIZE] = %u\n", hd.datum_size);

    fprintf (fp, "[LEGALESE BITS] = %u\n", hd.legalese_bits);
    fprintf (fp, "[LEGALESE TYPES] = %u\n", hd.pub.legaleses);
    fprintf (fp, "[LEGALESE SIZE] = %u\n", hd.legalese_size);

    fprintf (fp, "[CONSTITUENT BITS] = %u\n", hd.constituent_bits);
    fprintf (fp, "[CONSTITUENTS] = %u\n", hd.pub.constituents);
    fprintf (fp, "[CONSTITUENT SIZE] = %u\n", hd.constituent_size);

    fprintf (fp, "[TZFILE BITS] = %u\n", hd.tzfile_bits);
    fprintf (fp, "[TZFILES] = %u\n", hd.pub.tzfiles);
    fprintf (fp, "[TZFILE SIZE] = %u\n", hd.tzfile_size);

    fprintf (fp, "[COUNTRY BITS] = %u\n", hd.country_bits);
    fprintf (fp, "[COUNTRIES] = %u\n", hd.pub.countries);
    fprintf (fp, "[COUNTRY SIZE] = %u\n", hd.country_size);

    fprintf (fp, "[END OF FILE] = %u\n", hd.end_of_file);
    fprintf (fp, "[END OF ASCII HEADER DATA]\n");


    /*  Fill the remainder of the [HEADER SIZE] ASCII header with zeroes.  */

    start = (NV_INT32)ftell (fp);
    assert (start >= 0);
    for (i = start ; i < hd.header_size ; ++i) chk_fwrite (&zero, 1, 1, fp);
    fflush (fp);


    /*  Compute and save the checksum. */

    bit_pack (checksum_c, 0, 32, header_checksum ());
    chk_fwrite (checksum_c, 4, 1, fp);


    /*  NOTE : Using strcpy for character strings (no endian issue).  */

    /*  Write level units.  */

    pos = 0;
    size = hd.pub.level_unit_types * hd.level_unit_size;

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating unit write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.pub.level_unit_types ; ++i)
    {
        assert (strlen(hd.level_unit[i]) + 1 <= hd.level_unit_size);
        strcpy ((NV_CHAR *) &buf[pos], hd.level_unit[i]);
        pos += hd.level_unit_size;
    }

    chk_fwrite (buf, pos, 1, fp);
    free (buf);


    /*  Write direction units.  */

    pos = 0;
    size = hd.pub.dir_unit_types * hd.dir_unit_size;

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating unit write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.pub.dir_unit_types ; ++i)
    {
        assert (strlen(hd.dir_unit[i]) + 1 <= hd.dir_unit_size);
        strcpy ((NV_CHAR *) &buf[pos], hd.dir_unit[i]);
        pos += hd.dir_unit_size;
    }

    chk_fwrite (buf, pos, 1, fp);
    free (buf);


    /*  Write restrictions.  */

    pos = 0;
    size = hd.max_restriction_types * hd.restriction_size;

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating restriction write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.max_restriction_types ; ++i)
    {
        if (i == hd.pub.restriction_types) break;
        assert (strlen(hd.restriction[i]) + 1 <= hd.restriction_size);
        strcpy ((NV_CHAR *) &buf[pos], hd.restriction[i]);
        pos += hd.restriction_size;
    }
    memcpy (&buf[pos], "__END__", 7);

    chk_fwrite (buf, size, 1, fp);
    free (buf);


    /*  Write tzfiles.  */

    pos = 0;
    size = hd.max_tzfiles * hd.tzfile_size;

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating tzfile write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.max_tzfiles ; ++i)
    {
        if (i == hd.pub.tzfiles) break;
        assert (strlen(hd.tzfile[i]) + 1 <= hd.tzfile_size);
        strcpy ((NV_CHAR *) &buf[pos], hd.tzfile[i]);
        pos += hd.tzfile_size;
    }
    memcpy (&buf[pos], "__END__", 7);

    chk_fwrite (buf, size, 1, fp);
    free (buf);


    /*  Write countries.  */

    pos = 0;
    size = hd.max_countries * hd.country_size;

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating country write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.max_countries ; ++i)
    {
        if (i == hd.pub.countries) break;
        assert (strlen(hd.country[i]) + 1 <= hd.country_size);
        strcpy ((NV_CHAR *) &buf[pos], hd.country[i]);
        pos += hd.country_size;
    }
    memcpy (&buf[pos], "__END__", 7);

    chk_fwrite (buf, size, 1, fp);
    free (buf);


    /*  Write datums.  */

    pos = 0;
    size = hd.max_datum_types * hd.datum_size;

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating datum write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.max_datum_types ; ++i)
    {
        if (i == hd.pub.datum_types) break;
        assert (strlen(hd.datum[i]) + 1 <= hd.datum_size);
        strcpy ((NV_CHAR *) &buf[pos], hd.datum[i]);
        pos += hd.datum_size;
    }
    memcpy (&buf[pos], "__END__", 7);

    chk_fwrite (buf, size, 1, fp);
    free (buf);


    /*  Write legaleses.  */

    pos = 0;
    size = hd.max_legaleses * hd.legalese_size;

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating legalese write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.max_legaleses ; ++i)
    {
        if (i == hd.pub.legaleses) break;
        assert (strlen(hd.legalese[i]) + 1 <= hd.legalese_size);
        strcpy ((NV_CHAR *) &buf[pos], hd.legalese[i]);
        pos += hd.legalese_size;
    }
    memcpy (&buf[pos], "__END__", 7);

    chk_fwrite (buf, size, 1, fp);
    free (buf);


    /*  Write constituent names.  */

    pos = 0;
    size = hd.pub.constituents * hd.constituent_size;

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating constituent write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        assert (strlen(hd.constituent[i]) + 1 <= hd.constituent_size);
        strcpy ((NV_CHAR *) &buf[pos], hd.constituent[i]);
        pos += hd.constituent_size;
    }

    chk_fwrite (buf, pos, 1, fp);
    free (buf);


    /*  NOTE : Using bit_pack for integers.  */

    /*  Write speeds.  */

    pos = 0;
    size = bits2bytes (hd.pub.constituents * hd.speed_bits);

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating speed write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        temp_int = NINT (hd.speed[i] * hd.speed_scale) - hd.speed_offset;
        assert (temp_int >= 0);
        bit_pack (buf, pos, hd.speed_bits, temp_int);
        pos += hd.speed_bits;
    }

    chk_fwrite (buf, size, 1, fp);
    free (buf);


    /*  Write equilibrium arguments.  */

    pos = 0;
    size = bits2bytes (hd.pub.constituents *  hd.pub.number_of_years *
		       hd.equilibrium_bits);

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating equilibrium write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        NV_U_INT32 j;
        for (j = 0 ; j < hd.pub.number_of_years ; ++j)
        {
            temp_int = NINT (hd.equilibrium[i][j] * hd.equilibrium_scale) -
                hd.equilibrium_offset;
            assert (temp_int >= 0);
            bit_pack (buf, pos, hd.equilibrium_bits, temp_int);
            pos += hd.equilibrium_bits;
        }
    }

    chk_fwrite (buf, size, 1, fp);
    free (buf);


    /*  Write node factors.  */

    pos = 0;
    size = bits2bytes (hd.pub.constituents * hd.pub.number_of_years *
		       hd.node_bits);

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating node write buffer");
        exit (-1);
    }
    memset (buf, 0, size);

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        NV_U_INT32 j;
        for (j = 0 ; j < hd.pub.number_of_years ; ++j)
        {
            temp_int = NINT (hd.node_factor[i][j] * hd.node_scale) -
                hd.node_offset;
            assert (temp_int >= 0);
            bit_pack (buf, pos, hd.node_bits, temp_int);
            pos += hd.node_bits;
        }
    }

    chk_fwrite (buf, size, 1, fp);
    free (buf);
}


/*****************************************************************************\

    Function        unpack_string - Safely unpack a string into a
                    fixed-length buffer.

    Synopsis        unpack_string (buf, bufsize, pos, outbuf, outbuflen, desc);

                    NV_U_BYTE *buf          input buffer
                    NV_U_INT32 bufsize      size of input buffer in bytes
                    NV_U_INT32 *pos         current bit-position in buf
                                            (in-out parameter)
                    NV_CHAR *outbuf         fixed-length string-buffer
                    NV_U_INT32 outbuflen    size of outbuf in bytes
                    NV_CHAR *desc           description of the field being
                                            unpacked for use in warning
                                            messages when truncation occurs

    Returns         void

    Author          David Flater
    Date            2004-09-30

    pos will be left at the start of the next field even if the string
    gets truncated.

\*****************************************************************************/

static void unpack_string (NV_U_BYTE *buf, NV_U_INT32 bufsize, NV_U_INT32 *pos,
NV_CHAR *outbuf, NV_U_INT32 outbuflen, NV_CHAR *desc) {
  NV_U_INT32 i;
  NV_CHAR c = 'x';
  assert (buf);
  assert (pos);
  assert (outbuf);
  assert (desc);
  assert (outbuflen);
  --outbuflen;
  bufsize <<= 3;
  for (i = 0 ; c ; ++i) {
    assert (*pos < bufsize); /* Catch unterminated strings */
    c = bit_unpack (buf, *pos, 8);
    (*pos) += 8;
    if (i < outbuflen) {
      outbuf[i] = c;
    } else if (i == outbuflen) {
      outbuf[i] = '\0';
      if (c) {
        fprintf (stderr, "libtcd warning: truncating overlong %s\n", desc);
        fprintf (stderr, "The offending string starts with:\n%s\n", outbuf);
      }
    }
  }
}


/*****************************************************************************\

    Function        unpack_partial_tide_record - unpacks the "header" portion
                    of a tide record from the supplied buffer

    Synopsis        unpack_partial_tide_record (buf, rec, pos);

                    NV_U_BYTE *buf          input buffer
                    NV_U_INT32 bufsize      size of input buffer in bytes
                    TIDE_RECORD *rec        tide record
                    NV_U_INT32 *pos         final position in buffer after
                                            unpacking the header

    Returns         void

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

static void unpack_partial_tide_record (NV_U_BYTE *buf, NV_U_INT32 bufsize,
TIDE_RECORD *rec, NV_U_INT32 *pos)
{
    NV_INT32 temp_int;

    assert (buf);
    assert (rec);
    assert (pos);

    *pos = 0;

    rec->header.record_size = bit_unpack (buf, *pos, hd.record_size_bits);
    *pos += hd.record_size_bits;

    rec->header.record_type = bit_unpack (buf, *pos, hd.record_type_bits);
    *pos += hd.record_type_bits;

    temp_int = signed_bit_unpack (buf, *pos, hd.latitude_bits);
    rec->header.latitude = (NV_FLOAT64) temp_int / hd.latitude_scale;
    *pos += hd.latitude_bits;

    temp_int = signed_bit_unpack (buf, *pos, hd.longitude_bits);
    rec->header.longitude = (NV_FLOAT64) temp_int / hd.longitude_scale;
    *pos += hd.longitude_bits;

    /* This ordering doesn't match everywhere else but there's no technical
       reason to change it from its V1 ordering. */

    rec->header.tzfile = bit_unpack (buf, *pos, hd.tzfile_bits);
    *pos += hd.tzfile_bits;

    unpack_string (buf, bufsize, pos, rec->header.name, ONELINER_LENGTH, "station name");

    rec->header.reference_station =
	signed_bit_unpack (buf, *pos, hd.station_bits);
    *pos += hd.station_bits;

    assert (*pos <= bufsize*8);
}


/*****************************************************************************\

    Function        read_partial_tide_record - reads the "header" portion
                    of a tide record from the database.  This is used to index
                    the database on opening.

    Synopsis        read_partial_tide_record (num, rec);

                    NV_INT32 num            record number
                    TIDE_RECORD *rec        tide record

    Returns         NV_INT32                record number read

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

static NV_INT32 read_partial_tide_record (NV_INT32 num, TIDE_RECORD *rec)
{
    NV_U_BYTE               *buf;
    NV_U_INT32              maximum_possible_size, pos;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }

    assert (rec);

    /*  Read just the record size, record type, position, time zone, and
        name.  */

    maximum_possible_size = hd.record_size_bits + hd.record_type_bits +
        hd.latitude_bits + hd.longitude_bits + hd.tzfile_bits +
        (ONELINER_LENGTH * 8) + hd.station_bits;
    maximum_possible_size = bits2bytes (maximum_possible_size);

    if ((buf = (NV_U_BYTE *) calloc (maximum_possible_size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating partial tide record buffer");
        exit (-1);
    }

    current_record = num;
    fseek (fp, tindex[num].address, SEEK_SET);
    /* DWF 2007-12-02:  This is the one place where a short read would not
       necessarily mean catastrophe.  We don't know how long the partial
       record actually is yet, and it's possible that the full record will
       be shorter than maximum_possible_size.  So the return of fread is
       deliberately unchecked. */
    (void) fread (buf, maximum_possible_size, 1, fp);
    unpack_partial_tide_record (buf, maximum_possible_size, rec, &pos);
    free (buf);
    return (num);
}


/*****************************************************************************\

    Function        read_tide_db_header - reads the tide database header

    Synopsis        read_tide_db_header ();

    Returns         NV_BOOL                 NVTrue if header is correct

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

static NV_BOOL read_tide_db_header ()
{
    NV_INT32            temp_int;
    NV_CHAR             varin[ONELINER_LENGTH], *info;
    NV_U_INT32          utemp, i, j, pos, size, key_count;
    NV_U_BYTE           *buf, checksum_c[4];
    TIDE_RECORD         rec;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    exit (-1);
  }

    strcpy (hd.pub.version, "NO VERSION");

    /*  Compute the number of key phrases there are to match.  */
    key_count = sizeof (keys) / sizeof (KEY);

    /*  Zero out the header structure.  */
    memset (&hd, 0, sizeof (hd));

    /*  Handle the ASCII header data.  */
    while (fgets (varin, sizeof(varin), fp) != NULL)
    {
        if (strlen (varin) == ONELINER_LENGTH-1) {
          if (varin[ONELINER_LENGTH-2] != '\n') {
            fprintf (stderr, "libtcd error:  header line too long, begins with:\n");
            fprintf (stderr, "%s\n", varin);
            fprintf (stderr, "in file %s\n", filename);
            fprintf (stderr, "Configured limit is %u\n", ONELINER_LENGTH-1);
            fclose (fp);
            return NVFalse;
          }
        }

        if (strstr (varin, "[END OF ASCII HEADER DATA]")) break;

        /* All other lines must be field = value */
        info = strchr (varin, '=');
        if (!info) {
          fprintf (stderr, "libtcd error:  invalid tide db header line:\n");
          fprintf (stderr, "%s", varin);
          fprintf (stderr, "in file %s\n", filename);
          fclose (fp);
          return NVFalse;
        }
        ++info;

        /* Scan the fields per "keys" defined in tide_db_header.h. */
        for (i=0; i<key_count; ++i) {
          if (strstr (varin, keys[i].keyphrase)) {
            if (!strcmp (keys[i].datatype, "cstr"))
              strcpy (keys[i].address.cstr, clip_string(info));
            else if (!strcmp (keys[i].datatype, "i32")) {
              if (sscanf (info, "%d", keys[i].address.i32) != 1) {
          fprintf (stderr, "libtcd error:  invalid tide db header line:\n");
          fprintf (stderr, "%s", varin);
          fprintf (stderr, "in file %s\n", filename);
          fclose (fp);
          return NVFalse;
              }
            } else if (!strcmp (keys[i].datatype, "ui32")) {
              if (sscanf (info, "%u", keys[i].address.ui32) != 1) {
          fprintf (stderr, "libtcd error:  invalid tide db header line:\n");
          fprintf (stderr, "%s", varin);
          fprintf (stderr, "in file %s\n", filename);
          fclose (fp);
          return NVFalse;
              }
            } else
              assert (0);
          }
        }
    }

    /*  We didn't get a valid version string.  */

    if (!strcmp (hd.pub.version, "NO VERSION"))
    {
        fprintf (stderr, "libtcd error:  no version found in tide db header\n");
        fprintf (stderr, "in file %s\n", filename);
        fclose (fp);
        return NVFalse;
    }

    /* If no major or minor rev, they're 0 (pre-1.99) */
    if (hd.pub.major_rev > LIBTCD_MAJOR_REV) {
      fprintf (stderr, "libtcd error:  major revision in TCD file (%u) exceeds major revision of\n", hd.pub.major_rev);
      fprintf (stderr, "libtcd (%u).  You must upgrade libtcd to read this file.\n", LIBTCD_MAJOR_REV);
      fclose (fp);
      return NVFalse;
    }

    /*  Move to end of ASCII header.  */
    fseek (fp, hd.header_size, SEEK_SET);


    /*  Read and check the checksum. */

    chk_fread (checksum_c, 4, 1, fp);
    utemp = bit_unpack (checksum_c, 0, 32);

    if (utemp != header_checksum ()) {
#ifdef COMPAT114
      if (utemp != old_header_checksum ()) {
        fprintf (stderr,
            "libtcd error:  header checksum error in file %s\n", filename);
        fprintf (stderr, "Someone may have modified the ASCII portion of the header (don't do that),\n\
or it may just be corrupt.\n");
        fclose (fp);
        return NVFalse;
      }
#else
      fprintf (stderr,
          "libtcd error:  header checksum error in file %s\n", filename);
      fprintf (stderr, "Someone may have modified the ASCII portion of the header (don't do that),\n\
or it may be an ancient pre-version-1.02 TCD file, or it may just be corrupt.\n\
Pre-version-1.02 TCD files can be read by building libtcd with COMPAT114\n\
defined.\n");
      fclose (fp);
      return NVFalse;
#endif
    }
    fseek (fp, hd.header_size + 4, SEEK_SET);


    /*  Set the max possible restriction types based on the number of bits
        used.  */

    hd.max_restriction_types = NINT (pow (2.0,
        (NV_FLOAT64) hd.restriction_bits));


    /*  Set the max possible tzfiles based on the number of bits used.  */

    hd.max_tzfiles = NINT (pow (2.0, (NV_FLOAT64) hd.tzfile_bits));


    /*  Set the max possible countries based on the number of bits used.  */

    hd.max_countries = NINT (pow (2.0, (NV_FLOAT64) hd.country_bits));


    /*  Set the max possible datum types based on the number of bits
        used.  */

    hd.max_datum_types = NINT (pow (2.0, (NV_FLOAT64) hd.datum_bits));


    /*  Set the max possible legaleses based on the number of bits
        used.  */

    if (hd.pub.major_rev < 2)
      hd.max_legaleses = 1;
    else
      hd.max_legaleses = NINT (pow (2.0, (NV_FLOAT64) hd.legalese_bits));


    /*  NOTE : Using strcpy for character strings (no endian issue).  */

    /*  Read level units.  */

    hd.level_unit = (NV_CHAR **) calloc (hd.pub.level_unit_types,
        sizeof (NV_CHAR *));

    if ((buf = (NV_U_BYTE *) calloc (hd.level_unit_size,
        sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating level unit read buffer");
        exit (-1);
    }

    for (i = 0 ; i < hd.pub.level_unit_types ; ++i)
    {
        chk_fread (buf, hd.level_unit_size, 1, fp);
        hd.level_unit[i] = (NV_CHAR *) calloc (strlen((char*)buf) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.level_unit[i], (NV_CHAR *) buf);
    }
    free (buf);



    /*  Read direction units.  */

    hd.dir_unit = (NV_CHAR **) calloc (hd.pub.dir_unit_types,
        sizeof (NV_CHAR *));

    if ((buf = (NV_U_BYTE *) calloc (hd.dir_unit_size, sizeof (NV_U_BYTE))) ==
        NULL)
    {
        perror ("Allocating dir unit read buffer");
        exit (-1);
    }

    for (i = 0 ; i < hd.pub.dir_unit_types ; ++i)
    {
        chk_fread (buf, hd.dir_unit_size, 1, fp);
        hd.dir_unit[i] = (NV_CHAR *) calloc (strlen((char*)buf) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.dir_unit[i], (NV_CHAR *) buf);
    }
    free (buf);



    /*  Read restrictions.  */

    utemp = (NV_U_INT32)ftell (fp);
    hd.restriction = (NV_CHAR **) calloc (hd.max_restriction_types,
        sizeof (NV_CHAR *));

    if ((buf = (NV_U_BYTE *) calloc (hd.restriction_size,
        sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating restriction read buffer");
        exit (-1);
    }

    hd.pub.restriction_types = 0;
    for (i = 0 ; i < hd.max_restriction_types ; ++i)
    {
        chk_fread (buf, hd.restriction_size, 1, fp);
        if (!strcmp ((char*)buf, "__END__"))
        {
            hd.pub.restriction_types = i;
            break;
        }
        hd.restriction[i] = (NV_CHAR *) calloc (strlen((char*)buf) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.restriction[i], (NV_CHAR *) buf);
    }
    free (buf);
    fseek (fp, utemp + hd.max_restriction_types * hd.restriction_size,
        SEEK_SET);



    /*  Skip pedigrees. */
    if (hd.pub.major_rev < 2)
      fseek (fp, hd.pedigree_size * NINT (pow (2.0, (NV_FLOAT64) hd.pedigree_bits)), SEEK_CUR);
    hd.pub.pedigree_types = 1;



    /*  Read tzfiles.  */

    utemp = (NV_U_INT32)ftell (fp);
    hd.tzfile = (NV_CHAR **) calloc (hd.max_tzfiles, sizeof (NV_CHAR *));

    if ((buf = (NV_U_BYTE *) calloc (hd.tzfile_size, sizeof (NV_U_BYTE))) ==
        NULL)
    {
        perror ("Allocating tzfile read buffer");
        exit (-1);
    }

    hd.pub.tzfiles = 0;
    for (i = 0 ; i < hd.max_tzfiles ; ++i)
    {
        chk_fread (buf, hd.tzfile_size, 1, fp);
        if (!strcmp ((char*)buf, "__END__"))
        {
            hd.pub.tzfiles = i;
            break;
        }
        hd.tzfile[i] = (NV_CHAR *) calloc (strlen((char*)buf) + 1, sizeof (NV_CHAR));
        strcpy (hd.tzfile[i], (NV_CHAR *) buf);
    }
    free (buf);
    fseek (fp, utemp + hd.max_tzfiles * hd.tzfile_size, SEEK_SET);


    /*  Read countries.  */

    utemp = (NV_U_INT32)ftell (fp);
    hd.country = (NV_CHAR **) calloc (hd.max_countries, sizeof (NV_CHAR *));

    if ((buf = (NV_U_BYTE *) calloc (hd.country_size, sizeof (NV_U_BYTE))) ==
        NULL)
    {
        perror ("Allocating country read buffer");
        exit (-1);
    }

    hd.pub.countries = 0;
    for (i = 0 ; i < hd.max_countries ; ++i)
    {
        chk_fread (buf, hd.country_size, 1, fp);
        if (!strcmp ((char*)buf, "__END__"))
        {
            hd.pub.countries = i;
            break;
        }
        hd.country[i] = (NV_CHAR *) calloc (strlen((char*)buf) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.country[i], (NV_CHAR *) buf);
    }
    free (buf);
    fseek (fp, utemp + hd.max_countries * hd.country_size, SEEK_SET);


    /*  Read datums.  */

    utemp = (NV_U_INT32)ftell (fp);
    hd.datum = (NV_CHAR **) calloc (hd.max_datum_types, sizeof (NV_CHAR *));

    if ((buf = (NV_U_BYTE *) calloc (hd.datum_size, sizeof (NV_U_BYTE))) ==
        NULL)
    {
        perror ("Allocating datum read buffer");
        exit (-1);
    }

    hd.pub.datum_types = 0;
    for (i = 0 ; i < hd.max_datum_types ; ++i)
    {
        chk_fread (buf, hd.datum_size, 1, fp);
        if (!strcmp ((char*)buf, "__END__"))
        {
            hd.pub.datum_types = i;
            break;
        }
        hd.datum[i] = (NV_CHAR *) calloc (strlen((char*)buf) + 1, sizeof (NV_CHAR));
        strcpy (hd.datum[i], (NV_CHAR *) buf);
    }
    free (buf);
    fseek (fp, utemp + hd.max_datum_types * hd.datum_size, SEEK_SET);



    /*  Read legaleses.  */

    if (hd.pub.major_rev < 2) {
      hd.legalese = (NV_CHAR **) malloc (sizeof (NV_CHAR *));
      assert (hd.legalese != NULL);
      hd.legalese[0] = (NV_CHAR *) malloc (5 * sizeof (NV_CHAR));
      assert (hd.legalese[0] != NULL);
      strcpy (hd.legalese[0], "NULL");
      hd.pub.legaleses = 1;
    } else {
      utemp = (NV_U_INT32)ftell (fp);
      hd.legalese = (NV_CHAR **) calloc (hd.max_legaleses, sizeof (NV_CHAR *));

      if ((buf = (NV_U_BYTE *) calloc (hd.legalese_size, sizeof (NV_U_BYTE))) ==
	  NULL)
      {
	  perror ("Allocating legalese read buffer");
	  exit (-1);
      }

      hd.pub.legaleses = 0;
      for (i = 0 ; i < hd.max_legaleses ; ++i)
      {
	  chk_fread (buf, hd.legalese_size, 1, fp);
	  if (!strcmp ((char*)buf, "__END__"))
	  {
	      hd.pub.legaleses = i;
	      break;
	  }
	  hd.legalese[i] = (NV_CHAR *) calloc (strlen((char*)buf) + 1, sizeof (NV_CHAR));
	  strcpy (hd.legalese[i], (NV_CHAR *) buf);
      }
      free (buf);
      fseek (fp, utemp + hd.max_legaleses * hd.legalese_size, SEEK_SET);
    }



    /*  Read constituent names.  */

    hd.constituent =
        (NV_CHAR **) calloc (hd.pub.constituents, sizeof (NV_CHAR *));

    if ((buf = (NV_U_BYTE *) calloc (hd.constituent_size,
        sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating constituent read buffer");
        exit (-1);
    }

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        chk_fread (buf, hd.constituent_size, 1, fp);
        hd.constituent[i] = (NV_CHAR *) calloc (strlen((char*)buf) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.constituent[i], (NV_CHAR *) buf);
    }
    free (buf);


    if (hd.speed_offset < 0 || hd.equilibrium_offset < 0 ||
        hd.node_offset < 0) {
      fprintf (stderr, "libtcd WARNING:  File: %s\n", filename);
      fprintf (stderr, "WARNING:  This TCD file was created by a pre-version-1.11 libtcd.\n\
Versions of libtcd prior to 1.11 contained a serious bug that can result\n\
in overflows in the speeds, equilibrium arguments, or node factors.  This\n\
database should be rebuilt from the original data if possible.\n");
    }


    /*  NOTE: Using bit_unpack to get integers.  */

    /*  Read speeds.  */

    hd.speed = (NV_FLOAT64 *) calloc (hd.pub.constituents,
        sizeof (NV_FLOAT64));

    pos = 0;
    /* wasted byte bug in V1 */
    if (hd.pub.major_rev < 2)
      size = ((hd.pub.constituents * hd.speed_bits) / 8) + 1;
    else
      size = bits2bytes (hd.pub.constituents * hd.speed_bits);

    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating speed read buffer");
        exit (-1);
    }

    chk_fread (buf, size, 1, fp);

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        temp_int = bit_unpack (buf, pos, hd.speed_bits);
        hd.speed[i] = (NV_FLOAT64) (temp_int + hd.speed_offset) /
            hd.speed_scale;
        pos += hd.speed_bits;
        assert (hd.speed[i] >= 0.0);
    }
    free (buf);



    /*  Read equilibrium arguments.  */

    hd.equilibrium = (NV_FLOAT32 **) calloc (hd.pub.constituents,
        sizeof (NV_FLOAT32 *));

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        hd.equilibrium[i] = (NV_FLOAT32 *) calloc (hd.pub.number_of_years,
            sizeof (NV_FLOAT32));
    }



    pos = 0;
    /* wasted byte bug in V1 */
    if (hd.pub.major_rev < 2)
      size = ((hd.pub.constituents * hd.pub.number_of_years *
        hd.equilibrium_bits) / 8) + 1;
    else
      size = bits2bytes (hd.pub.constituents * hd.pub.number_of_years *
        hd.equilibrium_bits);


    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating equilibrium read buffer");
        exit (-1);
    }

    chk_fread (buf, size, 1, fp);

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        for (j = 0 ; j < hd.pub.number_of_years ; ++j)
        {
            temp_int = bit_unpack (buf, pos, hd.equilibrium_bits);
            hd.equilibrium[i][j] = (NV_FLOAT32) (temp_int +
                hd.equilibrium_offset) / hd.equilibrium_scale;
            pos += hd.equilibrium_bits;
        }
    }
    free (buf);



    /*  Read node factors.  */

    hd.node_factor = (NV_FLOAT32 **) calloc (hd.pub.constituents,
        sizeof (NV_FLOAT32 *));

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        hd.node_factor[i] =
            (NV_FLOAT32 *) calloc (hd.pub.number_of_years,
            sizeof (NV_FLOAT32));
    }


    pos = 0;
    /* wasted byte bug in V1 */
    if (hd.pub.major_rev < 2)
      size = ((hd.pub.constituents * hd.pub.number_of_years *
        hd.node_bits) / 8) + 1;
    else
      size = bits2bytes (hd.pub.constituents * hd.pub.number_of_years *
        hd.node_bits);


    if ((buf = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) == NULL)
    {
        perror ("Allocating node read buffer");
        exit (-1);
    }

    chk_fread (buf, size, 1, fp);

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        for (j = 0 ; j < hd.pub.number_of_years ; ++j)
        {
            temp_int = bit_unpack (buf, pos, hd.node_bits);
            hd.node_factor[i][j] = (NV_FLOAT32) (temp_int +
                hd.node_offset) / hd.node_scale;
            pos += hd.node_bits;
            assert (hd.node_factor[i][j] > 0.0);
        }
    }
    free (buf);


    /*  Read the header portion of all of the records in the file and save
        the record size, address, and name.  */

    /* DWF added test for zero 2003-11-16 -- happens on create new db */
    if (hd.pub.number_of_records) {
      if ((tindex = (TIDE_INDEX *) calloc (hd.pub.number_of_records,
          sizeof (TIDE_INDEX))) == NULL) {
          perror ("Allocating tide index");
          exit (-1);
      }
      /*  Set the first address to be immediately after the header  */
      tindex[0].address = (NV_INT32)ftell (fp);
    } else tindex = NULL; /* May as well be explicit... */

    for (i = 0 ; i < hd.pub.number_of_records ; ++i)
    {
        /*  Set the address for the next record so that
            read_partial_tide_record will know where to go.  */

        if (i) tindex[i].address = tindex[i - 1].address +
            rec.header.record_size;

        read_partial_tide_record (i, &rec);


        /*  Save the header info in the index.  */

        tindex[i].record_size = rec.header.record_size;
        tindex[i].record_type = rec.header.record_type;
        tindex[i].reference_station = rec.header.reference_station;
        assert (rec.header.tzfile >= 0);
        tindex[i].tzfile = rec.header.tzfile;
        tindex[i].lat = NINT (rec.header.latitude * hd.latitude_scale);
        tindex[i].lon = NINT (rec.header.longitude * hd.longitude_scale);

        if ((tindex[i].name =
            (NV_CHAR *) calloc (strlen (rec.header.name) + 1,
            sizeof (NV_CHAR))) == NULL)
        {
            perror ("Allocating index name memory");
            exit (-1);
        }

        strcpy (tindex[i].name, rec.header.name);
    }


    current_record = -1;
    current_index = -1;

    return (NVTrue);
}


/*****************************************************************************\

    Function        open_tide_db - opens the tide database

    Synopsis        open_tide_db (file);

                    NV_CHAR *file           database file name

    Returns         NV_BOOL                 NVTrue if file opened

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_BOOL open_tide_db (NV_CHAR *file)
{
    assert (file);
    current_record = -1;
    current_index = -1;
    if (fp) {
        if (!strcmp(file,filename) && !modified) return NVTrue;
        else close_tide_db();
    }
    if ((fp = fopen (file, "rb+")) == NULL) {
        if ((fp = fopen (file, "rb")) == NULL) return (NVFalse);
    }
    boundscheck_monologue (file);
    strcpy (filename, file);
    return (read_tide_db_header());
}


/*****************************************************************************\

    Function        close_tide_db - closes the tide database

    Synopsis        close_tide_db ();

    Returns         void

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

    If the global modified flag is true, the database header is rewritten
    before the database is closed.  The modified flag is then cleared.

\*****************************************************************************/

void close_tide_db ()
{
    NV_U_INT32 i;

    if (!fp) {
      fprintf (stderr, "libtcd warning: close_tide_db called when no database open\n");
      return;
    }

    /*  If we've changed something in the file, write the header to reset
        the last modified time.  */

    if (modified) write_tide_db_header ();


    /*  Free all of the temporary memory.  */

    assert (hd.constituent);
    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        if (hd.constituent[i] != NULL) free (hd.constituent[i]);
    }
    free (hd.constituent);
    hd.constituent = NULL;

    if (hd.speed != NULL) free (hd.speed);

    assert (hd.equilibrium);
    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        if (hd.equilibrium[i] != NULL) free (hd.equilibrium[i]);
    }
    free (hd.equilibrium);
    hd.equilibrium = NULL;

    assert (hd.node_factor);
    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        if (hd.node_factor[i] != NULL) free (hd.node_factor[i]);
    }
    free (hd.node_factor);
    hd.node_factor = NULL;

    assert (hd.level_unit);
    for (i = 0 ; i < hd.pub.level_unit_types ; ++i)
    {
        if (hd.level_unit[i] != NULL) free (hd.level_unit[i]);
    }
    free (hd.level_unit);
    hd.level_unit = NULL;

    assert (hd.dir_unit);
    for (i = 0 ; i < hd.pub.dir_unit_types ; ++i)
    {
        if (hd.dir_unit[i] != NULL) free (hd.dir_unit[i]);
    }
    free (hd.dir_unit);
    hd.dir_unit = NULL;

    assert (hd.restriction);
    for (i = 0 ; i < hd.max_restriction_types ; ++i)
    {
        if (hd.restriction[i] != NULL) free (hd.restriction[i]);
    }
    free (hd.restriction);
    hd.restriction = NULL;

    assert (hd.legalese);
    for (i = 0 ; i < hd.max_legaleses ; ++i)
    {
        if (hd.legalese[i] != NULL) free (hd.legalese[i]);
    }
    free (hd.legalese);
    hd.legalese = NULL;

    assert (hd.tzfile);
    for (i = 0 ; i < hd.max_tzfiles ; ++i)
    {
        if (hd.tzfile[i] != NULL) free (hd.tzfile[i]);
    }
    free (hd.tzfile);
    hd.tzfile = NULL;

    assert (hd.country);
    for (i = 0 ; i < hd.max_countries ; ++i)
    {
        if (hd.country[i] != NULL) free (hd.country[i]);
    }
    free (hd.country);
    hd.country = NULL;

    assert (hd.datum);
    for (i = 0 ; i < hd.max_datum_types ; ++i)
    {
        if (hd.datum[i] != NULL) free (hd.datum[i]);
    }
    free (hd.datum);
    hd.datum = NULL;

    /* tindex will still be null on create_tide_db */
    if (tindex) {
      for (i = 0 ; i < hd.pub.number_of_records ; ++i)
      {
          if (tindex[i].name) free (tindex[i].name);
      }
      free (tindex);
      tindex = NULL;
    }

    fclose (fp);
    fp = NULL;
    modified = NVFalse;

    /* Don't nullify the filename; there are places in the code where
       open_tide_db (filename) is invoked after close_tide_db().  This
       does not break the cache logic in open_tide_db because tindex
       is still nullified. */
}


/*****************************************************************************\

    Function        create_tide_db - creates the tide database

    Synopsis        create_tide_db (file, constituents, constituent, speed,
                        start_year, num_years, equilibrium, node_factor);

                    NV_CHAR *file              database file name
                    NV_U_INT32 constituents    number of constituents
                    NV_CHAR *constituent[]     constituent names
                    NV_FLOAT64 *speed          speed values
                    NV_INT32 start_year        start year
                    NV_U_INT32 num_years       number of years
                    NV_FLOAT32 *equilibrium[]  equilibrium arguments
                    NV_FLOAT32 *node_factor[]  node factors

    Returns         NV_BOOL                 NVTrue if file created

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_BOOL create_tide_db (NV_CHAR *file, NV_U_INT32 constituents,
NV_CHAR *constituent[], NV_FLOAT64 *speed, NV_INT32 start_year,
NV_U_INT32 num_years, NV_FLOAT32 *equilibrium[], NV_FLOAT32 *node_factor[])
{
    NV_U_INT32            i, j;
    NV_FLOAT64            min_value, max_value;
    NV_INT32              temp_int;

    /* Validate input */
    assert (file);
    assert (constituent);
    assert (speed);
    assert (equilibrium);
    assert (node_factor);
    for (i = 0 ; i < constituents ; ++i) {
      if (speed[i] < 0.0) {
        fprintf (stderr, "libtcd create_tide_db: somebody tried to set a negative speed (%f)\n", speed[i]);
        return NVFalse;
      }
      for (j = 0 ; j < num_years ; ++j) {
        if (node_factor[i][j] <= 0.0) {
          fprintf (stderr, "libtcd create_tide_db: somebody tried to set a negative or zero node factor (%f)\n", node_factor[i][j]);
          return NVFalse;
        }
      }
    }

    if (fp)
      close_tide_db();

    if ((fp = fopen (file, "wb+")) == NULL) {
      perror (file);
      return (NVFalse);
    }

    /*  Zero out the header structure.  */

    memset (&hd, 0, sizeof (hd));

    hd.pub.major_rev = LIBTCD_MAJOR_REV;
    hd.pub.minor_rev = LIBTCD_MINOR_REV;

    hd.header_size = DEFAULT_HEADER_SIZE;
    hd.pub.number_of_records = DEFAULT_NUMBER_OF_RECORDS;

    hd.pub.start_year = start_year;
    hd.pub.number_of_years = num_years;

    hd.pub.constituents = constituents;


    /*  Constituent names.  */

    hd.constituent =
        (NV_CHAR **) calloc (hd.pub.constituents, sizeof (NV_CHAR *));
    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        hd.constituent[i] = (NV_CHAR *) calloc (strlen (constituent[i]) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.constituent[i], constituent[i]);
    }


    /* A constituent count is stored with each reference station record,
       and it uses constituent_bits, so we need to be able to store
       the count itself (not just the values 0..count-1). */
    hd.constituent_bits = calculate_bits (hd.pub.constituents);


    /*  Set all of the speed attributes.  */

    hd.speed =  (NV_FLOAT64 *) calloc (hd.pub.constituents,
        sizeof (NV_FLOAT64));

    hd.speed_scale = DEFAULT_SPEED_SCALE;
    min_value = 99999999.0;
    max_value = -99999999.0;
    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        if (speed[i] < min_value) min_value = speed[i];
        if (speed[i] > max_value) max_value = speed[i];

        hd.speed[i] = speed[i];
    }

    /* DWF fixed sign reversal 2003-11-16 */
    /* DWF harmonized rounding with the way it is done in write_tide_db_header
       2007-01-22 */
    hd.speed_offset = (NINT (min_value * hd.speed_scale));
    temp_int = NINT (max_value * hd.speed_scale) - hd.speed_offset;
    assert (temp_int >= 0);
    hd.speed_bits = calculate_bits ((NV_U_INT32)temp_int);
    /* Generally 31.  With signed ints we don't have any bits to spare. */
    assert (hd.speed_bits < 32);

    /*  Set all of the equilibrium attributes.  */

    hd.equilibrium = (NV_FLOAT32 **) calloc (hd.pub.constituents,
        sizeof (NV_FLOAT32 *));

    hd.equilibrium_scale = DEFAULT_EQUILIBRIUM_SCALE;
    min_value = 99999999.0;
    max_value = -99999999.0;
    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        hd.equilibrium[i] = (NV_FLOAT32 *) calloc (hd.pub.number_of_years,
            sizeof (NV_FLOAT32));
        for (j = 0 ; j < hd.pub.number_of_years ; ++j)
        {
            if (equilibrium[i][j] < min_value) min_value = equilibrium[i][j];
            if (equilibrium[i][j] > max_value) max_value = equilibrium[i][j];

            hd.equilibrium[i][j] = equilibrium[i][j];
        }
    }

    /* DWF fixed sign reversal 2003-11-16 */
    /* DWF harmonized rounding with the way it is done in write_tide_db_header
       2007-01-22 */
    hd.equilibrium_offset = (NINT (min_value * hd.equilibrium_scale));
    temp_int = NINT (max_value * hd.equilibrium_scale) - hd.equilibrium_offset;
    assert (temp_int >= 0);
    hd.equilibrium_bits = calculate_bits ((NV_U_INT32)temp_int);


    /*  Set all of the node factor attributes.  */

    hd.node_factor = (NV_FLOAT32 **) calloc (hd.pub.constituents,
        sizeof (NV_FLOAT32 *));

    hd.node_scale = DEFAULT_NODE_SCALE;
    min_value = 99999999.0;
    max_value = -99999999.0;
    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        hd.node_factor[i] = (NV_FLOAT32 *) calloc (hd.pub.number_of_years,
            sizeof (NV_FLOAT32));
        for (j = 0 ; j < hd.pub.number_of_years ; ++j)
        {
            if (node_factor[i][j] < min_value) min_value =
                node_factor[i][j];
            if (node_factor[i][j] > max_value) max_value =
                node_factor[i][j];

            hd.node_factor[i][j] = node_factor[i][j];
        }
    }

    /* DWF fixed sign reversal 2003-11-16 */
    /* DWF harmonized rounding with the way it is done in write_tide_db_header
       2007-01-22 */
    hd.node_offset = (NINT (min_value * hd.node_scale));
    temp_int = NINT (max_value * hd.node_scale) - hd.node_offset;
    assert (temp_int >= 0);
    hd.node_bits = calculate_bits ((NV_U_INT32)temp_int);


    /*  Default city.  */

    hd.amplitude_bits = DEFAULT_AMPLITUDE_BITS;
    hd.amplitude_scale = DEFAULT_AMPLITUDE_SCALE;
    hd.epoch_bits = DEFAULT_EPOCH_BITS;
    hd.epoch_scale = DEFAULT_EPOCH_SCALE;

    hd.record_type_bits = DEFAULT_RECORD_TYPE_BITS;
    hd.latitude_bits = DEFAULT_LATITUDE_BITS;
    hd.latitude_scale = DEFAULT_LATITUDE_SCALE;
    hd.longitude_bits = DEFAULT_LONGITUDE_BITS;
    hd.longitude_scale = DEFAULT_LONGITUDE_SCALE;
    hd.record_size_bits = DEFAULT_RECORD_SIZE_BITS;

    hd.station_bits = DEFAULT_STATION_BITS;

    hd.datum_offset_bits = DEFAULT_DATUM_OFFSET_BITS;
    hd.datum_offset_scale = DEFAULT_DATUM_OFFSET_SCALE;
    hd.date_bits = DEFAULT_DATE_BITS;
    hd.months_on_station_bits = DEFAULT_MONTHS_ON_STATION_BITS;
    hd.confidence_value_bits = DEFAULT_CONFIDENCE_VALUE_BITS;

    hd.time_bits = DEFAULT_TIME_BITS;
    hd.level_add_bits = DEFAULT_LEVEL_ADD_BITS;
    hd.level_add_scale = DEFAULT_LEVEL_ADD_SCALE;
    hd.level_multiply_bits = DEFAULT_LEVEL_MULTIPLY_BITS;
    hd.level_multiply_scale = DEFAULT_LEVEL_MULTIPLY_SCALE;
    hd.direction_bits = DEFAULT_DIRECTION_BITS;

    hd.constituent_size = DEFAULT_CONSTITUENT_SIZE;
    hd.level_unit_size = DEFAULT_LEVEL_UNIT_SIZE;
    hd.dir_unit_size = DEFAULT_DIR_UNIT_SIZE;
    hd.restriction_size = DEFAULT_RESTRICTION_SIZE;
    hd.tzfile_size = DEFAULT_TZFILE_SIZE;
    hd.country_size = DEFAULT_COUNTRY_SIZE;
    hd.datum_size = DEFAULT_DATUM_SIZE;
    hd.legalese_size = DEFAULT_LEGALESE_SIZE;



    /*  Level units.  */

    hd.pub.level_unit_types = DEFAULT_LEVEL_UNIT_TYPES;
    hd.level_unit_bits = calculate_bits (hd.pub.level_unit_types - 1);

    hd.level_unit = (NV_CHAR **) calloc (hd.pub.level_unit_types,
        sizeof (NV_CHAR *));
    for (i = 0 ; i < hd.pub.level_unit_types ; ++i)
    {
        hd.level_unit[i] = (NV_CHAR *) calloc (strlen (level_unit[i]) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.level_unit[i], level_unit[i]);
    }


    /*  Direction units.  */

    hd.pub.dir_unit_types = DEFAULT_DIR_UNIT_TYPES;
    hd.dir_unit_bits = calculate_bits (hd.pub.dir_unit_types - 1);

    hd.dir_unit = (NV_CHAR **) calloc (hd.pub.dir_unit_types,
        sizeof (NV_CHAR *));
    for (i = 0 ; i < hd.pub.dir_unit_types ; ++i)
    {
        hd.dir_unit[i] = (NV_CHAR *) calloc (strlen (dir_unit[i]) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.dir_unit[i], dir_unit[i]);
    }


    /*  Restrictions.  */

    hd.restriction_bits = DEFAULT_RESTRICTION_BITS;
    hd.max_restriction_types = NINT (pow (2.0,
        (NV_FLOAT64) hd.restriction_bits));
    hd.pub.restriction_types = DEFAULT_RESTRICTION_TYPES;

    hd.restriction = (NV_CHAR **) calloc (hd.max_restriction_types,
        sizeof (NV_CHAR *));
    for (i = 0 ; i < hd.max_restriction_types ; ++i)
    {
        if (i == hd.pub.restriction_types) break;

        hd.restriction[i] = (NV_CHAR *) calloc (strlen (restriction[i]) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.restriction[i], restriction[i]);
    }


    /*  Legaleses.  */

    hd.legalese_bits = DEFAULT_LEGALESE_BITS;
    hd.max_legaleses = NINT (pow (2.0, (NV_FLOAT64) hd.legalese_bits));
    hd.pub.legaleses = DEFAULT_LEGALESES;

    hd.legalese = (NV_CHAR **) calloc (hd.max_legaleses,
        sizeof (NV_CHAR *));
    for (i = 0 ; i < hd.max_legaleses ; ++i)
    {
        if (i == hd.pub.legaleses) break;

        hd.legalese[i] = (NV_CHAR *) calloc (strlen (legalese[i]) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.legalese[i], legalese[i]);
    }


    /*  Tzfiles.  */

    hd.tzfile_bits = DEFAULT_TZFILE_BITS;
    hd.max_tzfiles = NINT (pow (2.0, (NV_FLOAT64) hd.tzfile_bits));
    hd.pub.tzfiles = DEFAULT_TZFILES;

    hd.tzfile = (NV_CHAR **) calloc (hd.max_tzfiles, sizeof (NV_CHAR *));
    for (i = 0 ; i < hd.max_tzfiles ; ++i)
    {
        if (i == hd.pub.tzfiles) break;

        hd.tzfile[i] = (NV_CHAR *) calloc (strlen (tzfile[i]) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.tzfile[i], tzfile[i]);
    }


    /*  Countries.  */

    hd.country_bits = DEFAULT_COUNTRY_BITS;
    hd.max_countries = NINT (pow (2.0, (NV_FLOAT64) hd.country_bits));
    hd.pub.countries = DEFAULT_COUNTRIES;

    hd.country = (NV_CHAR **) calloc (hd.max_countries, sizeof (NV_CHAR *));
    for (i = 0 ; i < hd.max_countries ; ++i)
    {
        if (i == hd.pub.countries) break;

        hd.country[i] = (NV_CHAR *) calloc (strlen (country[i]) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.country[i], country[i]);
    }


    /*  Datums.  */

    hd.datum_bits = DEFAULT_DATUM_BITS;
    hd.max_datum_types = NINT (pow (2.0, (NV_FLOAT64) hd.datum_bits));
    hd.pub.datum_types = DEFAULT_DATUM_TYPES;

    hd.datum = (NV_CHAR **) calloc (hd.max_datum_types, sizeof (NV_CHAR *));
    for (i = 0 ; i < hd.max_datum_types ; ++i)
    {
        if (i == hd.pub.datum_types) break;

        hd.datum[i] = (NV_CHAR *) calloc (strlen (xtideDatum[i]) + 1,
            sizeof (NV_CHAR));
        strcpy (hd.datum[i], xtideDatum[i]);
    }


    /*  Write the header to the file and close. */

    modified = NVTrue;
    close_tide_db ();


    /*  Re-open it and read the header from the file.  */

    i = (open_tide_db (file));


    /*  Set the correct end of file position since the one in the header is
        set to 0.  */
    hd.end_of_file = (NV_INT32)ftell(fp);
    /* DWF 2004-08-15: if the original program exits without adding any
       records, that doesn't help!  Rewrite the header with correct
       end_of_file. */
    write_tide_db_header ();

    return (i);
}


/*****************************************************************************\
  DWF 2004-10-13
  Used in check_tide_record.
\*****************************************************************************/
static NV_BOOL check_date (NV_U_INT32 date) {
  if (date) {
    unsigned m, d;
    date %= 10000;
    m = date / 100;
    d = date % 100;
    if (m < 1 || m > 12 || d < 1 || d > 31)
      return NVFalse;
  }
  return NVTrue;
}


/*****************************************************************************\
  DWF 2004-10-13
  Returns true iff a record is valid enough to write.  Reports all problems
  to stderr.  The checks are not designed to be airtight (e.g., if you
  use 360 degrees instead of 0 we'll let it slide).

  Mild side effects may occur:
  Note that the units-to-level-units COMPAT114 trick is wedged in here.
\*****************************************************************************/
static NV_BOOL check_tide_record (TIDE_RECORD *rec) {
  NV_U_INT32 i;
  NV_BOOL ret = NVTrue;

  if (!rec) {
    fprintf (stderr, "libtcd error: null pointer passed to check_tide_record\n");
    return NVFalse;
  }

  /* These are all static fields--if a buffer overflow has occurred on one
     of these, other fields might be invalid, but the problem started here. */
  boundscheck_oneliner (rec->header.name);
  boundscheck_oneliner (rec->source);
  boundscheck_monologue (rec->comments);
  boundscheck_monologue (rec->notes);
  boundscheck_oneliner (rec->station_id_context);
  boundscheck_oneliner (rec->station_id);
  boundscheck_monologue (rec->xfields);

#ifdef COMPAT114
  if (rec->header.record_type == REFERENCE_STATION && rec->units > 0)
    rec->level_units = rec->units;
#endif

  if (rec->header.latitude < -90.0 || rec->header.latitude > 90.0 ||
      rec->header.longitude < -180.0 || rec->header.longitude > 180.0) {
    fprintf (stderr, "libtcd error: bad coordinates in tide record\n");
    ret = NVFalse;
  }

  if (rec->header.tzfile < 0 || rec->header.tzfile >= (NV_INT32)hd.pub.tzfiles) {
    fprintf (stderr, "libtcd error: bad tzfile in tide record\n");
    ret = NVFalse;
  }

  if (rec->header.name[0] == '\0') {
    fprintf (stderr, "libtcd error: null name in tide record\n");
    ret = NVFalse;
  }

  if (rec->country < 0 || rec->country >= (NV_INT32)hd.pub.countries) {
    fprintf (stderr, "libtcd error: bad country in tide record\n");
    ret = NVFalse;
  }

  if (rec->restriction >= hd.pub.restriction_types) {
    fprintf (stderr, "libtcd error: bad restriction in tide record\n");
    ret = NVFalse;
  }

  if (rec->legalese >= hd.pub.legaleses) {
    fprintf (stderr, "libtcd error: bad legalese in tide record\n");
    ret = NVFalse;
  }

  if (!check_date (rec->date_imported)) {
    fprintf (stderr, "libtcd error: bad date_imported in tide record\n");
    ret = NVFalse;
  }

  if (rec->direction_units >= hd.pub.dir_unit_types) {
    fprintf (stderr, "libtcd error: bad direction_units in tide record\n");
    ret = NVFalse;
  }

  if (rec->min_direction < 0 || rec->min_direction > 361) {
    fprintf (stderr, "libtcd error: min_direction out of range in tide record\n");
    ret = NVFalse;
  }

  if (rec->max_direction < 0 || rec->max_direction > 361) {
    fprintf (stderr, "libtcd error: max_direction out of range in tide record\n");
    ret = NVFalse;
  }

  if (rec->level_units >= hd.pub.level_unit_types) {
    fprintf (stderr, "libtcd error: bad units in tide record\n");
    ret = NVFalse;
  }

  switch (rec->header.record_type) {
  case REFERENCE_STATION:
    if (rec->header.reference_station != -1) {
      fprintf (stderr, "libtcd error: type 1 record, reference_station != -1\n");
      ret = NVFalse;
    }

    if (rec->datum_offset < -13421.7728 || rec->datum_offset > 13421.7727) {
      fprintf (stderr, "libtcd error: datum_offset out of range in tide record\n");
      ret = NVFalse;
    }

    if (rec->datum < 0 || rec->datum >= (NV_INT32)hd.pub.datum_types) {
      fprintf (stderr, "libtcd error: bad datum in tide record\n");
      ret = NVFalse;
    }

    if (rec->zone_offset < -4096 || rec->zone_offset > 4095 ||
        rec->zone_offset % 100 >= 60) {
      fprintf (stderr, "libtcd error: bad zone_offset in tide record\n");
      ret = NVFalse;
    }

    if (!check_date (rec->expiration_date)) {
      fprintf (stderr, "libtcd error: bad expiration_date in tide record\n");
      ret = NVFalse;
    }

    if (rec->months_on_station > 1023) {
      fprintf (stderr, "libtcd error: months_on_station out of range in tide record\n");
      ret = NVFalse;
    }

    if (!check_date (rec->last_date_on_station)) {
      fprintf (stderr, "libtcd error: bad last_date_on_station in tide record\n");
      ret = NVFalse;
    }

    if (rec->confidence > 15) {
      fprintf (stderr, "libtcd error: confidence out of range in tide record\n");
      ret = NVFalse;
    }

    /* Only issue each error once. */
    for (i=0; i < hd.pub.constituents; ++i) {
      if (rec->amplitude[i] < 0.0 || rec->amplitude[i] > 52.4287) {
        fprintf (stderr, "libtcd error: constituent amplitude out of range in tide record\n");
        ret = NVFalse;
        break;
      }
    }
    for (i=0; i < hd.pub.constituents; ++i) {
      if (rec->epoch[i] < 0.0 || rec->epoch[i] > 360.0) {
        fprintf (stderr, "libtcd error: constituent epoch out of range in tide record\n");
        ret = NVFalse;
        break;
      }
    }

    break;

  case SUBORDINATE_STATION:
    if (rec->header.reference_station < 0 || rec->header.reference_station
    >= (NV_INT32)hd.pub.number_of_records) {
      fprintf (stderr, "libtcd error: bad reference_station in tide record\n");
      ret = NVFalse;
    }

    if (rec->min_time_add < -4096 || rec->min_time_add > 4095 ||
        rec->min_time_add % 100 >= 60) {
      fprintf (stderr, "libtcd error: bad min_time_add in tide record\n");
      ret = NVFalse;
    }

    if (rec->min_level_add < -65.536 || rec->min_level_add > 65.535) {
      fprintf (stderr, "libtcd error: min_level_add out of range in tide record\n");
      ret = NVFalse;
    }

    if (rec->min_level_multiply < 0.0 || rec->min_level_multiply > 65.535) {
      fprintf (stderr, "libtcd error: min_level_multiply out of range in tide record\n");
      ret = NVFalse;
    }

    if (rec->max_time_add < -4096 || rec->max_time_add > 4095 ||
        rec->max_time_add % 100 >= 60) {
      fprintf (stderr, "libtcd error: bad max_time_add in tide record\n");
      ret = NVFalse;
    }

    if (rec->max_level_add < -65.536 || rec->max_level_add > 65.535) {
      fprintf (stderr, "libtcd error: max_level_add out of range in tide record\n");
      ret = NVFalse;
    }

    if (rec->max_level_multiply < 0.0 || rec->max_level_multiply > 65.535) {
      fprintf (stderr, "libtcd error: max_level_multiply out of range in tide record\n");
      ret = NVFalse;
    }

    if (rec->flood_begins != NULLSLACKOFFSET && (rec->flood_begins < -4096 ||
    rec->flood_begins > 4095 || rec->flood_begins % 100 >= 60)) {
      fprintf (stderr, "libtcd error: bad flood_begins in tide record\n");
      ret = NVFalse;
    }

    if (rec->ebb_begins != NULLSLACKOFFSET && (rec->ebb_begins < -4096 ||
    rec->ebb_begins > 4095 || rec->ebb_begins % 100 >= 60)) {
      fprintf (stderr, "libtcd error: bad ebb_begins in tide record\n");
      ret = NVFalse;
    }

    break;

  default:
    fprintf (stderr, "libtcd error: invalid record_type in tide record\n");
    ret = NVFalse;
  }

  if (ret == NVFalse)
    dump_tide_record (rec);
  return ret;
}


/*****************************************************************************\
  DWF 2004-10-13
  Calculate size of a tide record as it would be encoded in the TCD file.
  Size is stored in record_size field.  Return is number of constituents
  that will be encoded.
\*****************************************************************************/
static NV_U_INT32 figure_size (TIDE_RECORD *rec) {
  NV_U_INT32 i, count=0, name_size, source_size, comments_size,
    notes_size, station_id_context_size, station_id_size, xfields_size;

  assert (rec);

  /*  Figure out how many bits we'll need for this record. */

  name_size = (NV_U_INT32)strlen(clip_string(rec->header.name))+1;
  source_size = (NV_U_INT32)strlen(clip_string(rec->source))+1;
  comments_size = (NV_U_INT32)strlen(clip_string(rec->comments))+1;
  notes_size = (NV_U_INT32)strlen(clip_string(rec->notes))+1;
  station_id_context_size = (NV_U_INT32)strlen(clip_string(rec->station_id_context))+1;
  station_id_size = (NV_U_INT32)strlen(clip_string(rec->station_id))+1;
  /* No clipping on xfields -- trailing \n required by syntax */
  xfields_size = (NV_U_INT32)strlen(rec->xfields)+1;

  rec->header.record_size =
      hd.record_size_bits +
      hd.record_type_bits +
      hd.latitude_bits +
      hd.longitude_bits +
      hd.station_bits +
      hd.tzfile_bits +
      (name_size * 8) +

      hd.country_bits +
      (source_size  * 8) +
      hd.restriction_bits +
      (comments_size * 8) +
      (notes_size * 8) +
      hd.legalese_bits +
      (station_id_context_size * 8) +
      (station_id_size * 8) +
      hd.date_bits + 
      (xfields_size * 8) +
      hd.dir_unit_bits +
      hd.direction_bits +
      hd.direction_bits +
      hd.level_unit_bits;

  switch (rec->header.record_type) {
  case REFERENCE_STATION:
    rec->header.record_size +=
        hd.datum_offset_bits +
        hd.datum_bits +
        hd.time_bits +
        hd.date_bits +
        hd.months_on_station_bits +
        hd.date_bits +
        hd.confidence_value_bits +
        hd.constituent_bits;

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        assert (rec->amplitude[i] >= 0.0);
        if (rec->amplitude[i] >= AMPLITUDE_EPSILON) ++count;
    }

    rec->header.record_size +=
        (count * hd.constituent_bits +
        count * hd.amplitude_bits +
        count * hd.epoch_bits);

    break;

  case SUBORDINATE_STATION:
    rec->header.record_size +=
        hd.time_bits +
        hd.level_add_bits +
        hd.level_multiply_bits +
        hd.time_bits +
        hd.level_add_bits +
        hd.level_multiply_bits +
        hd.time_bits +
        hd.time_bits;
    break;

  default:
    assert (0);
  }

  rec->header.record_size = bits2bytes (rec->header.record_size);
  return count;
}


/*****************************************************************************\
DWF 2004-10-14
\*****************************************************************************/
static void pack_string (NV_U_BYTE *buf, NV_U_INT32 *pos, NV_CHAR *s) {
  NV_U_INT32 i, temp_size;
  assert (buf);
  assert (pos);
  assert (s);
  temp_size = (NV_U_INT32)strlen(s)+1;
  for (i=0; i<temp_size; ++i) {
    bit_pack (buf, *pos, 8, s[i]);
    *pos += 8;
  }
}


/*****************************************************************************\

    Function        pack_tide_record - convert TIDE_RECORD to packed form

    Synopsis        pack_tide_record (rec, bufptr, bufsize);

                    TIDE_RECORD *rec        tide record (in)
                    NV_U_BYTE **bufptr      packed record (out)
                    NV_U_INT32 *bufsize     size of buf in bytes (out)

                    buf is allocated by pack_tide_record and should be
                    freed by the caller.

    Returns         void

    Author          Extracted from write_tide_record by David Flater
    Date            2006-05-26

\*****************************************************************************/

static void pack_tide_record (TIDE_RECORD *rec, NV_U_BYTE **bufptr,
NV_U_INT32 *bufsize) {
  NV_U_INT32              i, pos, constituent_count;
  NV_INT32                temp_int;
  NV_U_BYTE               *buf;

  /* Validate input */
  assert (rec);
  /* Cursory check for buffer overflows.  Should not happen here --
     check_tide_record does a more thorough job when called by add_tide_record
     and update_tide_record. */
  boundscheck_oneliner (rec->header.name);
  boundscheck_oneliner (rec->source);
  boundscheck_monologue (rec->comments);
  boundscheck_monologue (rec->notes);
  boundscheck_oneliner (rec->station_id_context);
  boundscheck_oneliner (rec->station_id);
  boundscheck_monologue (rec->xfields);

  constituent_count = figure_size (rec);

  if (!(*bufptr = (NV_U_BYTE *) calloc (rec->header.record_size,
				    sizeof (NV_U_BYTE)))) {
    perror ("libtcd can't allocate memory in pack_tide_record");
    exit (-1);
  }
  buf = *bufptr; /* To conserve asterisks */

  /*  Bit pack the common section.  "pos" is the bit position within the
      buffer "buf".  */

  pos = 0;

  bit_pack (buf, pos, hd.record_size_bits, rec->header.record_size);
  pos += hd.record_size_bits;

  bit_pack (buf, pos, hd.record_type_bits, rec->header.record_type);
  pos += hd.record_type_bits;

  temp_int = NINT (rec->header.latitude * hd.latitude_scale);
  bit_pack (buf, pos, hd.latitude_bits, temp_int);
  pos += hd.latitude_bits;

  temp_int = NINT (rec->header.longitude * hd.longitude_scale);
  bit_pack (buf, pos, hd.longitude_bits, temp_int);
  pos += hd.longitude_bits;

  /* This ordering doesn't match everywhere else but there's no technical
     reason to change it from its V1 ordering.  To do so would force
     another conditional in unpack_partial_tide_record. */

  bit_pack (buf, pos, hd.tzfile_bits, rec->header.tzfile);
  pos += hd.tzfile_bits;

  pack_string (buf, &pos, clip_string(rec->header.name));

  bit_pack (buf, pos, hd.station_bits, rec->header.reference_station);
  pos += hd.station_bits;

  bit_pack (buf, pos, hd.country_bits, rec->country);
  pos += hd.country_bits;

  pack_string (buf, &pos, clip_string(rec->source));

  bit_pack (buf, pos, hd.restriction_bits, rec->restriction);
  pos += hd.restriction_bits;

  pack_string (buf, &pos, clip_string(rec->comments));
  pack_string (buf, &pos, clip_string(rec->notes));

  bit_pack (buf, pos, hd.legalese_bits, rec->legalese);
  pos += hd.legalese_bits;

  pack_string (buf, &pos, clip_string(rec->station_id_context));
  pack_string (buf, &pos, clip_string(rec->station_id));

  bit_pack (buf, pos, hd.date_bits, rec->date_imported);
  pos += hd.date_bits;

  /* No clipping on xfields -- trailing \n required by syntax */
  pack_string (buf, &pos, rec->xfields);

  bit_pack (buf, pos, hd.dir_unit_bits, rec->direction_units);
  pos += hd.dir_unit_bits;

  bit_pack (buf, pos, hd.direction_bits, rec->min_direction);
  pos += hd.direction_bits;

  bit_pack (buf, pos, hd.direction_bits, rec->max_direction);
  pos += hd.direction_bits;

  /* The units-to-level-units compatibility hack is in check_tide_record */
  bit_pack (buf, pos, hd.level_unit_bits, rec->level_units);
  pos += hd.level_unit_bits;

  /*  Bit pack record type 1 records.  */

  if (rec->header.record_type == REFERENCE_STATION) {
      temp_int = NINT (rec->datum_offset * hd.datum_offset_scale);
      bit_pack (buf, pos, hd.datum_offset_bits, temp_int);
      pos += hd.datum_offset_bits;

      bit_pack (buf, pos, hd.datum_bits, rec->datum);
      pos += hd.datum_bits;

      bit_pack (buf, pos, hd.time_bits, rec->zone_offset);
      pos += hd.time_bits;

      bit_pack (buf, pos, hd.date_bits, rec->expiration_date);
      pos += hd.date_bits;

      bit_pack (buf, pos, hd.months_on_station_bits,
	  rec->months_on_station);
      pos += hd.months_on_station_bits;

      bit_pack (buf, pos, hd.date_bits, rec->last_date_on_station);
      pos += hd.date_bits;

      bit_pack (buf, pos, hd.confidence_value_bits, rec->confidence);
      pos += hd.confidence_value_bits;

      bit_pack (buf, pos, hd.constituent_bits, constituent_count);
      pos += hd.constituent_bits;

      for (i = 0 ; i < hd.pub.constituents ; ++i)
      {
	  if (rec->amplitude[i] >= AMPLITUDE_EPSILON)
	  {
	      bit_pack (buf, pos, hd.constituent_bits, i);
	      pos += hd.constituent_bits;

	      temp_int = NINT (rec->amplitude[i] * hd.amplitude_scale);
	      assert (temp_int);
	      bit_pack (buf, pos, hd.amplitude_bits, temp_int);
	      pos += hd.amplitude_bits;

	      temp_int = NINT (rec->epoch[i] * hd.epoch_scale);
	      bit_pack (buf, pos, hd.epoch_bits, temp_int);
	      pos += hd.epoch_bits;
	  }
      }
  }

  /*  Bit pack record type 2 records.  */
  else if (rec->header.record_type == SUBORDINATE_STATION) {
      bit_pack (buf, pos, hd.time_bits, rec->min_time_add);
      pos += hd.time_bits;

      temp_int = NINT (rec->min_level_add * hd.level_add_scale);
      bit_pack (buf, pos, hd.level_add_bits, temp_int);
      pos += hd.level_add_bits;

      temp_int = NINT (rec->min_level_multiply * hd.level_multiply_scale);
      bit_pack (buf, pos, hd.level_multiply_bits, temp_int);
      pos += hd.level_multiply_bits;

      bit_pack (buf, pos, hd.time_bits, rec->max_time_add);
      pos += hd.time_bits;

      temp_int = NINT (rec->max_level_add * hd.level_add_scale);
      bit_pack (buf, pos, hd.level_add_bits, temp_int);
      pos += hd.level_add_bits;

      temp_int = NINT (rec->max_level_multiply * hd.level_multiply_scale);
      bit_pack (buf, pos, hd.level_multiply_bits, temp_int);
      pos += hd.level_multiply_bits;

      bit_pack (buf, pos, hd.time_bits, rec->flood_begins);
      pos += hd.time_bits;

      bit_pack (buf, pos, hd.time_bits, rec->ebb_begins);
      pos += hd.time_bits;
  }

  else {
    fprintf (stderr, "libtcd error:  Record type %d is undefined\n",
	     rec->header.record_type);
    exit (-1);
  }

  *bufsize = rec->header.record_size;
  assert (*bufsize == bits2bytes (pos));
}


/*****************************************************************************\

    Function        write_tide_record - writes a tide record to the database

    Synopsis        write_tide_record (num, rec);

                    NV_INT32 num            record number:
                                            >= 0 overwrite record num
                                              -1 write at current file position
                    TIDE_RECORD *rec        tide record

    Returns         NV_BOOL                 NVTrue if successful

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

    hd.end_of_file is not updated by this function in any event.

\*****************************************************************************/

static NV_BOOL write_tide_record (NV_INT32 num, TIDE_RECORD *rec)
{
    NV_U_BYTE               *buf = NULL;
    NV_U_INT32              bufsize = 0;

    if (!fp) {
      fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
      return NVFalse;
    }
    write_protect();

    pack_tide_record (rec, &buf, &bufsize);

    if (num == -1)
      ;
    else if (num >= 0)
      fseek (fp, tindex[num].address, SEEK_SET);
    else
      assert (0);

    chk_fwrite (buf, bufsize, 1, fp);
    free (buf);
    modified = NVTrue;
    return NVTrue;
}


/*****************************************************************************\

    Function        read_next_tide_record - reads the next tide record from
                    the database

    Synopsis        read_next_tide_record (rec);

                    TIDE_RECORD *rec        tide record

    Returns         NV_INT32                record number of the tide record

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 read_next_tide_record (TIDE_RECORD *rec)
{
  return (read_tide_record (current_record + 1, rec));
}


/*****************************************************************************\

    Function        unpack_tide_record - convert TIDE_RECORD from packed form

    Synopsis        unpack_tide_record (buf, bufsize, rec);

                    NV_U_BYTE *buf          packed record (in)
                    NV_U_INT32 bufsize      size of buf in bytes (in)
                    TIDE_RECORD *rec        tide record (in-out)

                    rec must be allocated by the caller.

    Returns         void

    Author          Extracted from read_tide_record by David Flater
    Date            2006-05-26

    rec->header.record_number is initialized from the global current_record.

\*****************************************************************************/

static void unpack_tide_record (NV_U_BYTE *buf, NV_U_INT32 bufsize,
TIDE_RECORD *rec) {
  NV_INT32                temp_int;
  NV_U_INT32              i, j, pos, count;

  assert (rec);

  /* Initialize record */
  memset (rec, 0, sizeof (TIDE_RECORD));
  {
    int r = find_dir_units ("degrees true");
    assert (r > 0);
    rec->direction_units = (NV_U_BYTE)r;
  }
  rec->min_direction = rec->max_direction = 361;
  rec->flood_begins = rec->ebb_begins = NULLSLACKOFFSET;
  rec->header.record_number = current_record;

  unpack_partial_tide_record (buf, bufsize, rec, &pos);

  switch (rec->header.record_type) {
  case REFERENCE_STATION:
  case SUBORDINATE_STATION:
    break;
  default:
    fprintf (stderr, "libtcd fatal error: tried to read type %d tide record.\n", rec->header.record_type);
    fprintf (stderr, "This version of libtcd only supports types 1 and 2.  Perhaps you should\nupgrade.\n");
    exit (-1);
  }

  switch (hd.pub.major_rev) {

    /************************* TCD V1 *****************************/
  case 0:
  case 1:

    /*  "pos" is the bit position within the buffer "buf".  */

    rec->country = bit_unpack (buf, pos, hd.country_bits);
    pos += hd.country_bits;

    /* pedigree */
    pos += hd.pedigree_bits;

    unpack_string (buf, bufsize, &pos, rec->source, ONELINER_LENGTH, "source field");

    rec->restriction = bit_unpack (buf, pos, hd.restriction_bits);
    pos += hd.restriction_bits;

    unpack_string (buf, bufsize, &pos, rec->comments, MONOLOGUE_LENGTH, "comments field");

    if (rec->header.record_type == REFERENCE_STATION) {
      rec->level_units = bit_unpack (buf, pos, hd.level_unit_bits);
#ifdef COMPAT114
      rec->units = rec->level_units;
#endif
      pos += hd.level_unit_bits;

      temp_int = signed_bit_unpack (buf, pos, hd.datum_offset_bits);
      rec->datum_offset = (NV_FLOAT32) temp_int / hd.datum_offset_scale;
      pos += hd.datum_offset_bits;

      rec->datum = bit_unpack (buf, pos, hd.datum_bits);
      pos += hd.datum_bits;

      rec->zone_offset = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;

      rec->expiration_date = bit_unpack (buf, pos, hd.date_bits);
      pos += hd.date_bits;

      rec->months_on_station = bit_unpack (buf, pos,
          hd.months_on_station_bits);
      pos += hd.months_on_station_bits;

      rec->last_date_on_station = bit_unpack (buf, pos, hd.date_bits);
      pos += hd.date_bits;

      rec->confidence = bit_unpack (buf, pos, hd.confidence_value_bits);
      pos += hd.confidence_value_bits;

      for (i = 0 ; i < hd.pub.constituents ; ++i) {
        rec->amplitude[i] = 0.0;
        rec->epoch[i] = 0.0;
      }

      count = bit_unpack (buf, pos, hd.constituent_bits);
      pos += hd.constituent_bits;

      for (i = 0 ; i < count ; ++i) {
        j = bit_unpack (buf, pos, hd.constituent_bits);
        pos += hd.constituent_bits;

        rec->amplitude[j] = (NV_FLOAT32) bit_unpack (buf, pos,
            hd.amplitude_bits) / hd.amplitude_scale;
        pos += hd.amplitude_bits;

        rec->epoch[j] = (NV_FLOAT32) bit_unpack (buf, pos, hd.epoch_bits) /
            hd.epoch_scale;
        pos += hd.epoch_bits;
      }
    } else if (rec->header.record_type == SUBORDINATE_STATION) {
      rec->level_units = bit_unpack (buf, pos, hd.level_unit_bits);
      pos += hd.level_unit_bits;

      rec->direction_units = bit_unpack (buf, pos, hd.dir_unit_bits);
      pos += hd.dir_unit_bits;

      /* avg_level_units */
      pos += hd.level_unit_bits;

      rec->min_time_add = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;

      temp_int = signed_bit_unpack (buf, pos, hd.level_add_bits);
      rec->min_level_add = (NV_FLOAT32) temp_int / hd.level_add_scale;
      pos += hd.level_add_bits;

      /* Signed in V1 */
      temp_int = signed_bit_unpack (buf, pos, hd.level_multiply_bits);
      rec->min_level_multiply = (NV_FLOAT32) temp_int /
          hd.level_multiply_scale;
      pos += hd.level_multiply_bits;

      /* min_avg_level */
      pos += hd.level_add_bits;

      rec->min_direction = bit_unpack (buf, pos, hd.direction_bits);
      pos += hd.direction_bits;

      rec->max_time_add = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;

      temp_int = signed_bit_unpack (buf, pos, hd.level_add_bits);
      rec->max_level_add = (NV_FLOAT32) temp_int / hd.level_add_scale;
      pos += hd.level_add_bits;

      /* Signed in V1 */
      temp_int = signed_bit_unpack (buf, pos, hd.level_multiply_bits);
      rec->max_level_multiply = (NV_FLOAT32) temp_int /
          hd.level_multiply_scale;
      pos += hd.level_multiply_bits;

      /* max_avg_level */
      pos += hd.level_add_bits;

      rec->max_direction = bit_unpack (buf, pos, hd.direction_bits);
      pos += hd.direction_bits;

      rec->flood_begins = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;

      rec->ebb_begins = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;
    } else {
      assert (0);
    }
    break;

    /************************* TCD V2 *****************************/
  case 2:
    rec->country = bit_unpack (buf, pos, hd.country_bits);
    pos += hd.country_bits;

    unpack_string (buf, bufsize, &pos, rec->source, ONELINER_LENGTH, "source field");

    rec->restriction = bit_unpack (buf, pos, hd.restriction_bits);
    pos += hd.restriction_bits;

    unpack_string (buf, bufsize, &pos, rec->comments, MONOLOGUE_LENGTH, "comments field");
    unpack_string (buf, bufsize, &pos, rec->notes, MONOLOGUE_LENGTH, "notes field");

    rec->legalese = bit_unpack (buf, pos, hd.legalese_bits);
    pos += hd.legalese_bits;

    unpack_string (buf, bufsize, &pos, rec->station_id_context, ONELINER_LENGTH, "station_id_context field");
    unpack_string (buf, bufsize, &pos, rec->station_id, ONELINER_LENGTH, "station_id field");

    rec->date_imported = bit_unpack (buf, pos, hd.date_bits);
    pos += hd.date_bits;

    unpack_string (buf, bufsize, &pos, rec->xfields, MONOLOGUE_LENGTH, "xfields field");

    rec->direction_units = bit_unpack (buf, pos, hd.dir_unit_bits);
    pos += hd.dir_unit_bits;

    rec->min_direction = bit_unpack (buf, pos, hd.direction_bits);
    pos += hd.direction_bits;

    rec->max_direction = bit_unpack (buf, pos, hd.direction_bits);
    pos += hd.direction_bits;

    rec->level_units = bit_unpack (buf, pos, hd.level_unit_bits);
#ifdef COMPAT114
    rec->units = rec->level_units;
#endif
    pos += hd.level_unit_bits;

    if (rec->header.record_type == REFERENCE_STATION) {
      temp_int = signed_bit_unpack (buf, pos, hd.datum_offset_bits);
      rec->datum_offset = (NV_FLOAT32) temp_int / hd.datum_offset_scale;
      pos += hd.datum_offset_bits;

      rec->datum = bit_unpack (buf, pos, hd.datum_bits);
      pos += hd.datum_bits;

      rec->zone_offset = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;

      rec->expiration_date = bit_unpack (buf, pos, hd.date_bits);
      pos += hd.date_bits;

      rec->months_on_station = bit_unpack (buf, pos,
          hd.months_on_station_bits);
      pos += hd.months_on_station_bits;

      rec->last_date_on_station = bit_unpack (buf, pos, hd.date_bits);
      pos += hd.date_bits;

      rec->confidence = bit_unpack (buf, pos, hd.confidence_value_bits);
      pos += hd.confidence_value_bits;

      for (i = 0 ; i < hd.pub.constituents ; ++i) {
        rec->amplitude[i] = 0.0;
        rec->epoch[i] = 0.0;
      }

      count = bit_unpack (buf, pos, hd.constituent_bits);
      pos += hd.constituent_bits;

      for (i = 0 ; i < count ; ++i) {
        j = bit_unpack (buf, pos, hd.constituent_bits);
        pos += hd.constituent_bits;

        rec->amplitude[j] = (NV_FLOAT32) bit_unpack (buf, pos,
            hd.amplitude_bits) / hd.amplitude_scale;
        pos += hd.amplitude_bits;

        rec->epoch[j] = (NV_FLOAT32) bit_unpack (buf, pos, hd.epoch_bits) /
            hd.epoch_scale;
        pos += hd.epoch_bits;
      }
    } else if (rec->header.record_type == SUBORDINATE_STATION) {
      rec->min_time_add = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;

      temp_int = signed_bit_unpack (buf, pos, hd.level_add_bits);
      rec->min_level_add = (NV_FLOAT32) temp_int / hd.level_add_scale;
      pos += hd.level_add_bits;

      /* Made unsigned in V2 */
      temp_int = bit_unpack (buf, pos, hd.level_multiply_bits);
      rec->min_level_multiply = (NV_FLOAT32) temp_int /
          hd.level_multiply_scale;
      pos += hd.level_multiply_bits;

      rec->max_time_add = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;

      temp_int = signed_bit_unpack (buf, pos, hd.level_add_bits);
      rec->max_level_add = (NV_FLOAT32) temp_int / hd.level_add_scale;
      pos += hd.level_add_bits;

      /* Made unsigned in V2 */
      temp_int = bit_unpack (buf, pos, hd.level_multiply_bits);
      rec->max_level_multiply = (NV_FLOAT32) temp_int /
          hd.level_multiply_scale;
      pos += hd.level_multiply_bits;

      rec->flood_begins = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;

      rec->ebb_begins = signed_bit_unpack (buf, pos, hd.time_bits);
      pos += hd.time_bits;
    } else {
      assert (0);
    }
    break;

  default:
    assert (0);
  }

  assert (pos <= bufsize*8);
}


/*****************************************************************************\

    Function        read_tide_record - reads tide record "num" from the
                    database

    Synopsis        read_tide_record (num, rec);

                    NV_INT32 num            record number (in)
                    TIDE_RECORD *rec        tide record (in-out)

                    rec must be allocated by the caller.

    Returns         NV_INT32                num if success, -1 if failure

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_INT32 read_tide_record (NV_INT32 num, TIDE_RECORD *rec)
{
  NV_U_BYTE               *buf;
  NV_U_INT32              bufsize;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return -1;
  }

  if (num < 0 || num >= (NV_INT32)hd.pub.number_of_records)
    return -1;
  assert (rec);

  bufsize = tindex[num].record_size;
  if ((buf = (NV_U_BYTE *) calloc (bufsize, sizeof (NV_U_BYTE))) == NULL)
  {
      perror ("Allocating read_tide_record buffer");
      exit (-1);
  }

  current_record = num;
  require (fseek (fp, tindex[num].address, SEEK_SET) == 0);
  chk_fread (buf, tindex[num].record_size, 1, fp);
  unpack_tide_record (buf, bufsize, rec);
  free (buf);
  return num;
}


/*****************************************************************************\

    Function        add_tide_record - adds a tide record to the database

    Synopsis        add_tide_record (rec);

                    TIDE_RECORD *rec        tide record

    Returns         NV_BOOL                 NVTrue if successful

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_BOOL add_tide_record (TIDE_RECORD *rec, DB_HEADER_PUBLIC *db)
{
    NV_INT32                pos;

    if (!fp) {
      fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
      return NVFalse;
    }
    write_protect();

    if (!check_tide_record (rec))
      return NVFalse;

    fseek (fp, hd.end_of_file, SEEK_SET);
    pos = (NV_INT32)ftell (fp);
    assert (pos > 0);

    rec->header.record_number = hd.pub.number_of_records++;

    if (write_tide_record (-1, rec))
    {
        if ((tindex = (TIDE_INDEX *) realloc (tindex, hd.pub.number_of_records *
            sizeof (TIDE_INDEX))) == NULL)
        {
            perror ("Allocating more index records");
            exit (-1);
        }

        tindex[rec->header.record_number].address = pos;
        tindex[rec->header.record_number].record_size = rec->header.record_size;
        tindex[rec->header.record_number].record_type = rec->header.record_type;
        tindex[rec->header.record_number].reference_station =
            rec->header.reference_station;
        assert (rec->header.tzfile >= 0);
        tindex[rec->header.record_number].tzfile = rec->header.tzfile;
        tindex[rec->header.record_number].lat = NINT (rec->header.latitude *
            hd.latitude_scale);
        tindex[rec->header.record_number].lon = NINT (rec->header.longitude *
            hd.longitude_scale);


        if ((tindex[rec->header.record_number].name =
            (NV_CHAR *) calloc (strlen (rec->header.name) + 1,
            sizeof (NV_CHAR))) == NULL)
        {
            perror ("Allocating index name memory");
            exit (-1);
        }


        strcpy (tindex[rec->header.record_number].name, rec->header.name);
        pos = (NV_INT32)ftell (fp);
        assert (pos > 0);
        hd.end_of_file = pos;
        modified = NVTrue;

        /*  Get the new number of records.  */
        if (db)
          *db = hd.pub;

        return NVTrue;
    }

    return NVFalse;
}


/*****************************************************************************\

    Function        delete_tide_record - deletes a record and all subordinate
                    records from the database

    Synopsis        delete_tide_record (num);

                    NV_INT32 num            record number

    Returns         NV_BOOL                 NVTrue if successful

    Author          Jan C. Depner (redone by David Flater)
    Date            08/01/02 (2006-05-26)

    See libtcd.html for changelog.

\*****************************************************************************/

NV_BOOL delete_tide_record (NV_INT32 num, DB_HEADER_PUBLIC *db)
{
  NV_INT32          i, newrecnum, *map;
  NV_U_BYTE         **allrecs_packed;

  if (!fp) {
    fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
    return NVFalse;
  }
  write_protect();

  if (num < 0 || num >= (NV_INT32)hd.pub.number_of_records) return NVFalse;

  /* Allocate workspace */

  if (!(map = (NV_INT32 *) malloc (hd.pub.number_of_records * sizeof(NV_INT32)))) {
    perror ("libtcd: delete_tide_record: can't malloc");
    return NVFalse;
  }
  if (!(allrecs_packed = (NV_U_BYTE **) malloc (hd.pub.number_of_records * sizeof(NV_U_BYTE*)))) {
    perror ("libtcd: delete_tide_record: can't malloc");
    free (map);
    return NVFalse;
  }

  /* First pass: read in database, build record number map and mark records
     for deletion */

  require (fseek (fp, tindex[0].address, SEEK_SET) == 0);
  for (newrecnum=0,i=0; i<(NV_INT32)hd.pub.number_of_records; ++i) {
    assert (ftell(fp) == tindex[i].address);
    if (i == num || (tindex[i].record_type == SUBORDINATE_STATION && tindex[i].reference_station == num)) {
      map[i] = -1;
      allrecs_packed[i] = NULL;
      require (fseek (fp, tindex[i].record_size, SEEK_CUR) == 0);
    } else {
      map[i] = newrecnum++;
      if (!(allrecs_packed[i] = (NV_U_BYTE *) malloc (tindex[i].record_size))) {
	perror ("libtcd: delete_tide_record: can't malloc");
	for (--i; i>=0; --i)
	  free (allrecs_packed[i]);
	free (allrecs_packed);
	free (map);
	return NVFalse;
      }
      chk_fread (allrecs_packed[i], tindex[i].record_size, 1, fp);
    }
  }

  /* Second pass: rewrite database and fix substation linkage */

  require (fseek (fp, tindex[0].address, SEEK_SET) == 0);
  require (ftruncate (fileno(fp), tindex[0].address) == 0);

  for (i=0; i<(NV_INT32)hd.pub.number_of_records; ++i)
    if (map[i] >= 0) {
      if (tindex[i].record_type == SUBORDINATE_STATION) {
        assert (tindex[i].reference_station >= 0);
        assert (tindex[i].reference_station <= (NV_INT32)hd.pub.number_of_records);
        if (map[tindex[i].reference_station] != tindex[i].reference_station) {
          /* Fix broken reference station linkage */
          TIDE_RECORD rec;
          unpack_tide_record (allrecs_packed[i], tindex[i].record_size, &rec);
          free (allrecs_packed[i]);
          rec.header.reference_station = map[tindex[i].reference_station];
          pack_tide_record (&rec, &(allrecs_packed[i]), &(tindex[i].record_size));
        }
      }
      chk_fwrite (allrecs_packed[i], tindex[i].record_size, 1, fp);
      free (allrecs_packed[i]);
    }

  /* Free workspace (packed records were freed above) */

  free (allrecs_packed);
  free (map);

  /* Flush, reopen, renew.  The index is now garbage; close and reopen
     to reindex. */

  hd.end_of_file = (NV_U_INT32)ftell(fp);
  hd.pub.number_of_records = newrecnum;
  modified = NVTrue;
  close_tide_db ();
  open_tide_db (filename);

  if (db)
    *db = hd.pub;

  return NVTrue;
}


/*****************************************************************************\

    Function        update_tide_record - updates a tide record in the database

    Synopsis        update_tide_record (num, rec);

                    NV_INT32 num            record number
                    TIDE_RECORD *rec        tide record

    Returns         NV_BOOL                 NVTrue if successful

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

#ifdef COMPAT114
NV_BOOL update_tide_record (NV_INT32 num, TIDE_RECORD *rec)
#else
NV_BOOL update_tide_record (NV_INT32 num, TIDE_RECORD *rec, DB_HEADER_PUBLIC *db)
#endif
{
    NV_INT32                pos, size;
    TIDE_RECORD             tmp_rec;
    NV_U_BYTE               *block = NULL;

    if (!fp) {
      fprintf (stderr, "libtcd error: attempt to access database when database not open\n");
      return NVFalse;
    }
    write_protect();

    if (num < 0 || num >= (NV_INT32)hd.pub.number_of_records) return NVFalse;

    if (!check_tide_record (rec))
      return NVFalse;

    figure_size (rec);
    read_tide_record (num, &tmp_rec);
    if (rec->header.record_size != tmp_rec.header.record_size)
    {
        /*  Aaaaaaarrrrrgggggghhhh!!!!  We have to move stuff!  */

        /*  Save where we are - end of record being modified.  */
        pos = (NV_INT32)ftell (fp);
        assert (pos > 0);

        /*  Figure out how big a block we need to move.  */
        size = hd.end_of_file - pos;
        assert (size >= 0);

        /*  Allocate memory and read the block.  */
        if (size)
        {
            if ((block = (NV_U_BYTE *) calloc (size, sizeof (NV_U_BYTE))) ==
                NULL)
            {
                perror ("Allocating block");
                return NVFalse;
            }
            chk_fread (block, size, 1, fp);
        }

        /*  Write out the modified record.  */
        write_tide_record (num, rec);

        /*  If we weren't at the end of file, move the block.  */
        if (size)
        {
            chk_fwrite (block, size, 1, fp);
            free (block);
        }

        hd.end_of_file = (NV_U_INT32)ftell (fp);

        /*  Close the file and reopen it to index the records again.  */
        close_tide_db ();
        open_tide_db (filename);
    }

    /*  The easy way.  No change to the record size.  */
    else
    {
        write_tide_record (num, rec);

        /*  Save the header info in the index.  */
        tindex[num].record_size = rec->header.record_size;
        tindex[num].record_type = rec->header.record_type;
        tindex[num].reference_station = rec->header.reference_station;
        tindex[num].tzfile = rec->header.tzfile;
        tindex[num].lat = NINT (rec->header.latitude * hd.latitude_scale);
        tindex[num].lon = NINT (rec->header.longitude * hd.longitude_scale);

        /* AH maybe? */
        /* DWF: agree, same size record does not imply that name length
           is identical. */
	if (strcmp(tindex[num].name, rec->header.name) != 0) {
	  free(tindex[num].name);
	  tindex[num].name = (NV_CHAR *) calloc (strlen (rec->header.name) + 1, sizeof (NV_CHAR));
	  strcpy(tindex[num].name, rec->header.name);
	}
    }

#ifndef COMPAT114
    if (db)
      *db = hd.pub;
#endif

    return (NVTrue);
}


/*****************************************************************************\

    Function        infer_constituents - computes inferred constituents when
                    M2, S2, K1, and O1 are given.  This function fills the
                    remaining unfilled constituents.  The inferred constituents
                    are developed or decided based on article 230 of
                    "Manual of Harmonic Analysis and Prediction of Tides",
                    Paul Schureman, C & GS special publication no. 98,
                    October 1971.  This function is really just for NAVO
                    since we go to weird places and put in tide gages for
                    ridiculously short periods of time so we only get a
                    few major constituents developed.  This function was
                    modified from the NAVO FORTRAN program pred_tide_corr,
                    subroutine infer.ftn, 08-oct-86.

    Synopsis        infer_constituents (rec);

                    TIDE_RECORD rec         tide record

    Returns         NV_BOOL                 NVFalse if not enough constituents
                                            available to infer others

    Author          Jan C. Depner
    Date            08/01/02

    See libtcd.html for changelog.

\*****************************************************************************/

NV_BOOL infer_constituents (TIDE_RECORD *rec)
{
    NV_U_INT32        i, j;
    NV_INT32          m2, s2, k1, o1;
    NV_FLOAT32        epoch_m2, epoch_s2, epoch_k1, epoch_o1;

    assert (rec);
    require ((m2 = find_constituent ("M2")) >= 0);
    require ((s2 = find_constituent ("S2")) >= 0);
    require ((k1 = find_constituent ("K1")) >= 0);
    require ((o1 = find_constituent ("O1")) >= 0);

    if (rec->amplitude[m2] == 0.0 || rec->amplitude[s2] == 0.0 ||
        rec->amplitude[k1] == 0.0 || rec->amplitude[o1] == 0.0)
        return (NVFalse);

    epoch_m2 = rec->epoch[m2];
    epoch_s2 = rec->epoch[s2];
    epoch_k1 = rec->epoch[k1];
    epoch_o1 = rec->epoch[o1];

    for (i = 0 ; i < hd.pub.constituents ; ++i)
    {
        if (rec->amplitude[i] == 0.0 && rec->epoch[i] == 0.0)
        {
            for (j = 0 ; j < INFERRED_SEMI_DIURNAL_COUNT ; ++j)
            {
                if (!strcmp (inferred_semi_diurnal[j], get_constituent (i)))
                {
                    /*  Compute the inferred semi-diurnal constituent.  */

                    rec->amplitude[i] = (semi_diurnal_coeff[j] / coeff[0]) *
                        rec->amplitude[m2];

                    if (fabs ((NV_FLOAT64) (epoch_s2 - epoch_m2)) > 180.0)
                    {
                        if (epoch_s2 < epoch_m2)
                        {
                            epoch_s2 += 360.0;
                        }
                        else
                        {
                            epoch_m2 += 360.0;
                        }
                    }
                    rec->epoch[i] = epoch_m2 + ((hd.speed[i] - hd.speed[m2]) /
                        (hd.speed[s2] - hd.speed[m2])) * (epoch_s2 - epoch_m2);
                }
            }


            for (j = 0 ; j < INFERRED_DIURNAL_COUNT ; ++j)
            {
                if (!strcmp (inferred_diurnal[j], get_constituent (i)))
                {
                    /*  Compute the inferred diurnal constituent.  */

                    rec->amplitude[i] = (diurnal_coeff[j] / coeff[1]) *
                        rec->amplitude[o1];

                    if (fabs ((NV_FLOAT64) (epoch_k1 - epoch_o1)) > 180.0)
                    {
                        if (epoch_k1 < epoch_o1)
                        {
                            epoch_k1 += 360.0;
                        }
                        else
                        {
                            epoch_o1 += 360.0;
                        }
                    }
                    rec->epoch[i] = epoch_o1 + ((hd.speed[i] - hd.speed[o1]) /
                        (hd.speed[k1] - hd.speed[o1])) * (epoch_k1 - epoch_o1);
                }
            }
        }
    }

    return (NVTrue);
}
