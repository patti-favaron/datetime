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
