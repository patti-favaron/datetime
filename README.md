# datetime: a modern Fortran library for simple, time-zone independent, date and time management

## Problem, and necessity

Modern Fortran provides various functions and subroutines dealing with time, including for example "date_and_time", but contains no specific functionality addressing "time and date management" like computing the difference between two dates, or generating the date and time string corresponding to "now" plus three days.

Actions like these, however, are common in data processing: one case of the many, for example, is to automatically generate all expected file names in a data set gathered by some time-bound automatic data acquisition facility.

One possible line of action is to generate information like this externally, for example a Python script, and feed it into the procedure.

Another is to write an own set of functions, and use them personally.

One other more, to write an own set of functions and share it.


## Usage

This module is available with the [Fortran package manager](https://fpm.fortran-lang.org).
To use it in your project add the following dependency to your package manifest

```toml
[dependencies]
datetime.git = "https://github.com/patti-favaron/datetime"
```

You can also directly copy the source from [`src/datetime.f90`](./src/datetime.f90) to your project.

## Known limits and issues

No provisions have been taken to deal with sub-second time fractions (this may be addressed in a future version).

Leap years are managed, but leap _seconds_ are not.

The library ```datetime``` is a work-in-progress. ☺️

## Description

### Nature and purpose (as imagined by the author)

The module Fortran-90 'datetime.f90' is a lean implementation of date and time management, with resolution down to 1s, designed to deal with "local" calendar operations.

The use case imagined by the author is to complement slow-sampling data with time stamps, and performing on them basic operations like adding/subtracting a time interval.

Other uses are possible as well however. 😊

### Basic assumptions

No time zone is considered: date and times are always "local", that is, conventionally attributed to the local time zone central meridian.

As a consequence, no automatic passage to and from time-saving is done.

### Definitions

As the ```datetime``` library deals with "dates and times", it could be interesting to know what tha author considers a "date", and what a "time".

A date-and-time (datetime for brevity) is a time instant, expressed with a one second resolution, valid since the "local epoch".

The "local epoch" is the datetime 1970-01-01T00:00:00 _in the local time zone_. According to this definition, the local epoch of time zone CET is not the same as the local epoch in GMT zone.

The "epoch", or "global epoch", is the GMT/UMT local epoch. This term is introduced just for clarity, as ```datetime``` only deals with local epoch.

Within ```datetime``` the terms "date and time" and "time" are considered synonymous: no time separated from date is considered.

The term "date" is intended as a date and time where hour, minute and second are ignored. As a result of conversion to date, hour minute and second are forced to zero. But this is by no means mandatory: the only requirement is hour, minute and second are valid.

### Data types

#### Overview

Three ime data types are used within 'datetime' module:

- User-defined type 'Time', representing a date and time encoded as year, month in year (1 to 12), day in month (1 to 28, 29, 30 or 31 depending on month and year), hour (0 to 23), minute (0 to 59) and second (0 to 59).
- Numeric time, encoded as a 32 bit integer representing the displcement of current time from the "local epoch", that is, 1970-01-01 00:00:00 according to the central meridian.
- Strings, representing times in ISO format.

Conversion functions exist, allowing to transform one form into the other.

#### 'Time' user defined type

The 'Time' user defined type is defined as

    type Time
        integer(2)  :: iYear
        integer(1)  :: iMonth
        integer(1)  :: iDay
        integer(1)  :: iHour
        integer(1)  :: iMinute
        integer(1)  :: iSecond
    end type Time

No member functions are defined within 'Time'. As we'll see, functions exist in the library whose argument list include objects of type 'Time' as arguments.

To initialize a 'Time' object the standard Fortran constructor syntax

    tTime = Time(2000_2, 1_1, 1_1, 0_1, 0_1, 0_1)
    
The _2 and _1 suffixes are the Fortran way to specify integer(2) and integer(1) literals respectively.


#### Function list

##### Get current time

Call:

    tTime = now()
    
Arguments:

    type(Time) :: tTime

Notes:

- Function ```now()``` is actually a wrapper of standard Fortran subroutine ```date_and_time```.

##### Build time from default integer values

Call:

    tTime = toTime(iYear, iMonth, iDay, iHour, iMinute, iSecond)
    
Arguments:

    integer, intent(in) :: iYear    ! Year, including century
    integer, intent(in) :: iMonth   ! Month, 1 to 12, with 1 = January, ..., 12 = December
    integer, intent(in) :: iDay     ! Day in month, 1 to usual month dependent limit
    integer, intent(in) :: iHour    ! Hour, 0 to 23
    integer, intent(in) :: iMinute  ! Minute, 0 to 59
    integer, intent(in) :: iSecond  ! Second, 0 to 59
    type(Time)          :: tTime    ! Result
    
Notes:

- No validity check is made on arguments.
- Individual argument values are converted from default integer to the actual length of corresponding type element.

##### Convert from Time to epoch

Call:

    iEpoch = toEpoch(tTime)
    
Arguments:

    type(Time), intent(in)  :: tTime    ! Object of type Time to be converted
    integer                 :: iEpoch   ! Result
    
Notes:

- The result represents the displacement, in seconds, of time from the Local Epoch, that is 01. 01. 1970 relative to local central meridian.
- For 32 bits default integer, the maximum date representable without overflow is 18. 01. 2038.

##### Convert from epoch to Time

Call:

    tTime = fromEpoch(iEpoch)
    
Arguments:

    integer, intent(in) :: iEpoch   ! Epoch value to convert
    type(Time)          :: tTime    ! Result

Notes:

- For 32 bits default integer, the maximum date representable without overflow is 18. 01. 2038.

##### Julian day corresponding to a Time value

Call:

    iJDay = julianDay(tTime)
    
Arguments:

    type(Time), intent(in)  :: tTime    ! Object of type Time to be converted
    integer                 :: iJDay    ! Result
    
Notes:

- The result represents the Julian day relative to local central meridian.
- The number of day-in-year can be computed by adding 1 to the difference of current time Julian day from the Julian day of current time's start of year.

##### Date corresponding to a Julian day

Call:

    tTime = date(iJDay)
    
Arguments:

    integer, intent(in) :: iJDay    ! Julian day to be converted
    type(Time)          :: tTime    ! Result
    
Notes:

- The result represents a "date", defined as a time value whose hour, minute and second parts are ignored during use.
- Hour, minute and second are forced to 0.

##### Convert string to time

Call:

    tTime = fromString(sISOTime)

Arguments:

    character(len=19), intent(in)   :: sISOTime ! String containing a date and time in ISO form (YYYY-MM-DD HH:MM:SS)
    type(Time)                      :: tTime    ! Result
    
Notes:

- The character represented as blank inside the example template string (YYYY-MM-DD HH:MM:SS) is in reality ignored, and can be inserted as anything. For example, it may be a "T" as in 2023-03-08T10:30:00.

##### Convert time to ISO string

Call:

    sISOTime = toString(tTime, lTeeForm)

Arguments:

    type(Time), intent(in)          :: tTime    ! Time value to be converted
    logical, intent(in), optional   :: lTeeForm ! .true.: string with a T separator as in 2023-03-08T10:30:00; .false. (default): blank
    character(len=19)               :: sISOTime ! Result
    
Notes:

- The use of a blank or "T" separator between date and time should be compared to actual uses. The default is a blank (acknowledged easily by various importers, like for example R's ```read.csv``` function.

##### Convert string with date only to time

Call:

    tTime = fromDayString(sISODate)

Arguments:

    character(len=10), intent(in)   :: sISODate ! String containing a date in ISO form (YYYY-MM-DD)
    type(Time)                      :: tTime    ! Result
    
Notes:

- Hour, minute and second in ```tTime``` are forced to 0.

##### Convert time to ISO string with date only

Call:

    sISODate = toDayString(tTime)

Arguments:

    type(Time), intent(in)          :: tTime    ! Time value to be converted
    character(len=10)               :: sISOTime ! Result
    
Notes:

- Whatever hour, minute and second in ```tTime```, their value is ignored during conversion.

#### Operator list

##### Date addition

Call:

    tTimeShifted = tTime + iTimeDelta
    
Arguments:

    type(Time)  :: tTimeShifted ! Shifted time
    type(Time)  :: tTime        ! Original time
    integer     :: iTimeDelta   ! Time to add, in seconds (may be zero or negative)

##### Date subtraction - difference

Calls:

    tTimeShifted = tTime - iTimeDelta
    
    iTimeDelta = tTimeTo - tTimeFrom
    
Arguments:

    type(Time)  :: tTimeShifted ! Shifted time
    type(Time)  :: tTime        ! Original time
    type(Time)  :: tTimeFrom    ! Original time 1
    type(Time)  :: tTimeTo      ! Original time 2
    integer     :: iTimeDelta   ! Time to add, in seconds (may be zero or negative)

Notes:

- The operator is polymorphic.
