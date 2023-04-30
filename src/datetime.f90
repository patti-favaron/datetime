!------------------------------------------------------------------
! datetime
!
! Module, supporting the treatment of date and time information, down to
! the resolution of 1s.
!
! Written by: Patrizia Favaron
! e-mail:     patti.favaron@gmail.com
!
!------------------------------------------------------------------
! Statement of Licensing Conditions
!------------------------------------------------------------------
!
! Copyright 2023 Patrizia Favaron
!
! Permission is hereby granted, free of charge, to any person
! obtaining a copy of this software and associated documentation
! files (the "Software"), to deal in the Software without
! restriction, including without limitation the rights to use,
! copy, modify, merge, publish, distribute, sublicense, and/or
! sell copies of the Software, and to permit persons to whom the
! Software is furnished to do so, subject to the following conditions:
!
! The above copyright notice and this permission notice shall be
! included in all copies or substantial portions of the Software.
!
! THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
! EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
! OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
! NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
! HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
! WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
! FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
! OTHER DEALINGS IN THE SOFTWARE.
!
!------------------------------------------------------------------
!
module datetime
    
    implicit none
    
    private
    
    ! Public interface: procedures
    public  :: Time
    public  :: isValid
    public  :: now
    public  :: toTime
    public  :: toEpoch
    public  :: fromEpoch
    public  :: julianDay
    public  :: date
    public  :: fromString
    public  :: toString
    public  :: fromDayString
    public  :: toDayString
    public  :: operator(+)
    public  :: operator(-)
    
    ! Public interface: constants
    integer, parameter, public  :: DTM_ONE_SECOND = 1
    integer, parameter, public  :: DTM_ONE_MINUTE = 60 * DTM_ONE_SECOND
    integer, parameter, public  :: DTM_ONE_HOUR   = 60 * DTM_ONE_MINUTE
    integer, parameter, public  :: DTM_ONE_DAY    = 24 * DTM_ONE_HOUR
    
    ! Data types
    
    type Time
        integer(2)  :: iYear
        integer(1)  :: iMonth
        integer(1)  :: iDay
        integer(1)  :: iHour
        integer(1)  :: iMinute
        integer(1)  :: iSecond
    end type Time
    
    ! Interfaces
    
    interface operator(+)
        module procedure timeAdd
    end interface operator(+)
    
    interface operator(-)
        module procedure timeSubtract
        module procedure timeDelta
    end interface operator(-)
    
    ! Constants
    integer, parameter  :: DATE_REFORM_DAY  = 588829 ! 15 October 1582, with 31-days months
    integer, parameter  :: BASE_DAYS        = 1720995
    real, parameter     :: YEAR_DURATION    = 365.25
    real, parameter     :: MONTH_DURATION   = 30.6001
    integer, parameter  :: BASE_DAY         = 2440588
    integer, parameter  :: LIMIT_JULIAN_DAY = 2299161
    integer, parameter  :: CORRECTION_DAYS  = 1524

contains

    function now() result(tTime)
        
        ! Routine arguments
        type(Time)  :: tTime
        
        ! Locals
        integer, dimension(9)   :: ivValues
        
        ! Get date and time corresponding to "now"
        call date_and_time(values = ivValues)
        
        ! Dispatch components
        tTime % iYear   = int(ivValues(1), kind=2)
        tTime % iMonth  = int(ivValues(2), kind=1)
        tTime % iDay    = int(ivValues(3), kind=1)
        tTime % iHour   = int(ivValues(5), kind=1)
        tTime % iMinute = int(ivValues(6), kind=1)
        tTime % iSecond = int(ivValues(7), kind=1)
        
    end function now
    
    
    function isValid(tTime) result(lIsValid)
        
        ! Routine arguments
        type(Time), intent(in)  :: tTime
        logical                 :: lIsValid
        
        ! Locals
        
        ! Assume success (will falsify on failure)
        lIsValid = .true.
        
        ! Check time part
        if( &
            tTime % iHour < 0_1   .or. tTime % iHour >= 24_1   .or. &
            tTime % iMinute < 0_1 .or. tTime % iMinute >= 60_1 .or. &
            tTime % iSecond < 0_1 .or. tTime % iSecond >= 60_1      &
        ) then
            
            lIsValid = .false.
        
        else
        
            ! Check date part
            if(tTime % iMonth == 2_1) then
                if(mod(tTime % iYear, 4_2) == 0_2) then
                    if(tTime % iDay < 1_1 .or. tTime % iDay > 29_1) then
                        lIsValid = .false.
                    end if
                else
                    if(tTime % iDay < 1_1 .or. tTime % iDay > 28_1) then
                        lIsValid = .false.
                    end if
                end if
            elseif(tTime % iMonth == 4_1 .or. tTime % iMonth == 6_1 .or. tTime % iMonth == 9_1 .or. tTime % iMonth == 11_1) then
                if(tTime % iDay < 1_1 .or. tTime % iDay > 30_1) then
                    lIsValid = .false.
                end if
            else
                if(tTime % iDay < 1_1 .or. tTime % iDay > 31_1) then
                    lIsValid = .false.
                end if
            end if
        
        end if
        
    end function isValid
    

    function toTime(iYear, iMonth, iDay, iHour, iMinute, iSecond, lIsValid) result(tTime)
        
        ! Routine arguments
        integer, intent(in)             :: iYear
        integer, intent(in)             :: iMonth
        integer, intent(in)             :: iDay
        integer, intent(in)             :: iHour
        integer, intent(in)             :: iMinute
        integer, intent(in)             :: iSecond
        logical, intent(out), optional  :: lIsValid
        type(Time)                      :: tTime
        
        ! Locals
        ! --none--
        
        ! Dispatch components
        tTime % iYear   = int(iYear,   kind=2)
        tTime % iMonth  = int(iMonth,  kind=1)
        tTime % iDay    = int(iDay,    kind=1)
        tTime % iHour   = int(iHour,   kind=1)
        tTime % iMinute = int(iMinute, kind=1)
        tTime % iSecond = int(iSecond, kind=1)
        
        ! Validate, if requested
        if(present(lIsValid)) then
            lIsValid = isValid(tTime)
        end if
        
    end function toTime
    
    
    function toEpoch(tTime) result(iEpoch)
        
        ! Routine arguments
        type(Time), intent(in)  :: tTime
        integer                 :: iEpoch
        
        ! Locals
        integer :: iJulianDay
        integer :: iJulianSecond
        
        ! Check input parameters for validity
        if( &
            tTime % iHour   < 0 .or. tTime % iHour   > 23 .or. &
            tTime % iMinute < 0 .or. tTime % iMinute > 59 .or. &
            tTime % iSecond < 0 .or. tTime % iSecond > 59 &
        ) then
            iEpoch = -1
            return
        end if
        
        ! Compute based Julian day
        iJulianDay = julianDay(tTime) - BASE_DAY
        
        ! Convert based Julian day to second, and add seconds from time,
        ! regardless of hour type.
        iJulianSecond = iJulianDay * 24 * 3600
        iEpoch = iJulianSecond + tTime % iSecond + 60*(tTime % iMinute + 60*tTime % iHour)
        
    end function toEpoch
    
    
    function fromEpoch(iEpoch) result(tTime)
        
        ! Routine arguments
        type(Time)          :: tTime
        integer, intent(in) :: iEpoch
        
        ! Locals
        integer :: iJulianDay
        integer :: iTimeSeconds
        
        ! Check parameter
        if(iEpoch < 0) then
            tTime = Time(1970, 1, 1, 0, 0, 0)
            return
        end if
        
        ! Isolate the date and time parts
        iJulianDay = iEpoch/(24*3600) + BASE_DAY
        iTimeSeconds = mod(iEpoch, 24*3600)
        
        ! Process the date part
        tTime = date(iJulianDay)
        
        ! Extract time from the time part
        tTime % iSecond = int(mod(iTimeSeconds, 60), kind=1)
        iTimeSeconds    = iTimeSeconds / 60
        tTime % iMinute = int(mod(iTimeSeconds, 60), kind=1)
        tTime % iHour   = int(iTimeSeconds / 60, kind=1)
        
    end function fromEpoch
    

    function julianDay(tTime) result(iJulianDay)

        ! Routine arguments
        type(Time), intent(in)  :: tTime
        integer                 :: iJulianDay

        ! Locals
        integer     :: iAuxYear
        integer     :: iAuxMonth
        integer     :: iCentury
        integer     :: iTryJulianDay
        integer     :: iNumDays
        
        ! Check year against invalid values. Only positive
        ! years are supported in this version. Year "0" does
        ! not exist.
        if(tTime % iYear <= 0) then
            iJulianDay = -9999
            return
        end if

        ! Check month and day to look valid (a rough, non-month-aware
        ! test is intentionally adopted in sake of simplicity)
        if((.not.(1<=tTime % iMonth .and. tTime % iMonth<=12)) .or. (.not.(1<=tTime % iDay .and. tTime % iDay<=31))) then
            iJulianDay = -9999
            return
        end if

        ! Preliminary estimate the Julian day, based on
        ! the average duration of year and month in days.
        if(tTime % iMonth > 2) then
            iAuxYear  = tTime % iYear
            iAuxMonth = tTime % iMonth + 1
        else
            iAuxYear  = tTime % iYear - 1
            iAuxMonth = tTime % iMonth + 13
        end if
        iTryJulianDay = floor(YEAR_DURATION * iAuxYear) + floor(MONTH_DURATION * iAuxMonth) + tTime % iDay + BASE_DAYS

        ! Correct estimate if later than the date reform day
        iNumDays = tTime % iDay + 31*tTime % iMonth + 372*tTime % iYear
        if(iNumDays >= DATE_REFORM_DAY) then
            iCentury = int(0.01*iAuxYear)
            iJulianDay = iTryJulianDay - iCentury + iCentury/4 + 2
        else
            iJulianDay = iTryJulianDay
        end if

    end function julianDay


    function date(iJulianDay) result(tTime)

        ! Routine arguments
        integer, intent(in)     :: iJulianDay
        type(Time)              :: tTime

        ! Locals
        integer :: iDeviation
        integer :: iPreJulianDay
        integer :: iPostJulianDay
        integer :: iYearIndex
        integer :: iMonthIndex
        integer :: iDayIndex
        
        ! Unwind Pope Gregorius' day correction
        if(iJulianDay >= LIMIT_JULIAN_DAY) then
            iDeviation = floor(((iJulianDay-1867216)-0.25)/36524.25)
            iPreJulianDay = iJulianDay + iDeviation - iDeviation/4 + 1
        else
            iPreJulianDay = iJulianDay
        end if
        iPostJulianDay = iPreJulianDay + CORRECTION_DAYS

        ! Compute time indices
        iYearIndex  = floor(6680+((iPostJulianDay-2439870)-122.1)/YEAR_DURATION)
        iDayIndex   = 365*iYearIndex + iYearIndex/4
        iMonthIndex = floor((iPostJulianDay - iDayIndex)/MONTH_DURATION)

        ! Compute date elements
        tTime % iDay = int(iPostJulianDay - floor(MONTH_DURATION*iMonthIndex) - iDayIndex, kind=1)
        if(iMonthIndex > 13) then
            tTime % iMonth = int(iMonthIndex - 13, kind=1)
        else
            tTime % iMonth = int(iMonthIndex - 1, kind=1)
        end if
        tTime % iYear = int(iYearIndex - 4715, kind=2)
        if(tTime % iMonth > 2_1) tTime % iYear = tTime % iYear - 1_2
        tTime % iHour   = 0_1
        tTime % iMinute = 0_1
        tTime % iSecond = 0_1

    end function date
    
    
    function fromString(sDateTime) result(tDateTime)
        
        ! Routine arguments
        character(len=19), intent(in)   :: sDateTime
        type(Time)                      :: tDateTime
        
        ! Locals
        integer :: iErrCode
        
        ! Perform conversion to ISO string
        read(sDateTime, "(i4.4,2(1x,i2.2),1x,i2.2,2(1x,i2.2))", iostat=iErrCode) &
            tDateTime % iYear, &
            tDateTime % iMonth, &
            tDateTime % iDay, &
            tDateTime % iHour, &
            tDateTime % iMinute, &
            tDateTime % iSecond
        if(iErrCode /= 0) then
            tDateTime = Time(1970_2, 1_1, 1_1, 0_1, 0_1, 0_1)
        end if
        
    end function fromString
    
    
    function toString(tDateTime, lTeeForm) result(sDateTime)
        
        ! Routine arguments
        type(Time), intent(in)          :: tDateTime
        logical, intent(in), optional   :: lTeeForm     ! If .true, a 'T' is used insted of blank to separate date from time (default: .false.)
        character(len=19)               :: sDateTime
        
        ! Locals
        character   :: cSeparator
        
        ! Manager optional parameters
        if(present(lTeeForm)) then
            if(lTeeForm) then
                cSeparator = "T"
            else
                cSeparator = " "
            end if
        else
            cSeparator = " "
        end if
        
        ! Perform conversion to ISO string
        write(sDateTime, "(i4.4,2('-',i2.2),a1,i2.2,2(':',i2.2))") &
            tDateTime % iYear, &
            tDateTime % iMonth, &
            tDateTime % iDay, &
            cSeparator, &
            tDateTime % iHour, &
            tDateTime % iMinute, &
            tDateTime % iSecond
        
    end function toString
    
    
    function fromDayString(sDateTime) result(tDateTime)
        
        ! Routine arguments
        character(len=10), intent(in)   :: sDateTime
        type(Time)                      :: tDateTime
        
        ! Locals
        integer :: iErrCode
        
        ! Perform conversion to ISO string
        read(sDateTime, "(i4.4,2(1x,i2.2))", iostat=iErrCode) &
            tDateTime % iYear, &
            tDateTime % iMonth, &
            tDateTime % iDay
        if(iErrCode /= 0) then
            tDateTime = Time(1970_2, 1_1, 1_1, 0_1, 0_1, 0_1)
        end if
        tDateTime % iHour   = 0_1
        tDateTime % iMinute = 0_1
        tDateTime % iSecond = 0_1
        
    end function fromDayString
    
    
    function toDayString(tDateTime) result(sDateTime)
        
        ! Routine arguments
        type(Time), intent(in)          :: tDateTime
        character(len=10)               :: sDateTime
        
        ! Locals
        ! --none--
        
        ! Perform conversion to ISO string
        write(sDateTime, "(i4.4,2('-',i2.2))") &
            tDateTime % iYear, &
            tDateTime % iMonth, &
            tDateTime % iDay
        
    end function toDayString
    
    
    function timeAdd(tDateTime, iShift) result(tNewTime)
        
        ! Routine arguments
        type(Time), intent(in)  :: tDateTime
        integer, intent(in)     :: iShift
        type(Time)              :: tNewTime
        
        ! Locals
        ! --none--
        
        ! Perform addition through forward-backwards conversion
        tNewTime = fromEpoch(toEpoch(tDateTime) + iShift)
        
    end function timeAdd
    
    
    function timeSubtract(tDateTime, iShift) result(tNewTime)
        
        ! Routine arguments
        type(Time), intent(in)  :: tDateTime
        integer, intent(in)     :: iShift
        type(Time)              :: tNewTime
        
        ! Locals
        ! --none--
        
        ! Perform addition through forward-backwards conversion
        tNewTime = fromEpoch(toEpoch(tDateTime) - iShift)
        
    end function timeSubtract
    
    
    function timeDelta(tDateTimeA, tDateTimeB) result(iDeltaTime)
        
        ! Routine arguments
        type(Time), intent(in)  :: tDateTimeA
        type(Time), intent(in)  :: tDateTimeB
        integer                 :: iDeltaTime
        
        ! Locals
        ! --none--
        
        ! Perform addition through forward-backwards conversion
        iDeltaTime = toEpoch(tDateTimeA) - toEpoch(tDateTimeB)
        
    end function timeDelta
    
end module datetime

