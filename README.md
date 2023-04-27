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


## Description

### Nature and purpose (as imagined by the author)

The module Fortran-90 'datetime.f90' is a lean implementation of date and time management, with resolution down to 1s, designed to deal with "local" calendar operations.

The use case imagined by the author is to complement slow-sampling data with time stamps, and performing on them basic operations like adding/subtracting a time interval.

Other uses are possible as well however. 😊

### Basic assumptions

No time zone is considered: date and times are always "local", that is, conventionally attributed to the local time zone central meridian.

As a consequence, no automatic passage to and from time-saving is done.

### Data types

#### Overview

Three ime data types are used within 'datetime' module:

- User-defined type 'Time', representing a date and time encoded as year, month in year (1 to 12), day in month (1 to 28, 29, 30 or 31 depending on month and year), hour (0 to 23), minute (0 to 59) and second (0 to 59).
- Numeric time, encoded as a 32 bit integer representing the displcement of current time from the "local epoch", that is, 1970-01-01 00:00:00 according to the central meridian.
- 
