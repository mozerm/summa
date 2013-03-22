module paramCheck_module
! define numerical recipes data type
USE nrtype
! define look-up values for the choice of method to combine and sub-divide snow layers
USE mDecisions_module,only:&
 sameRulesAllLayers, & ! SNTHERM option: same combination/sub-dividion rules applied to all layers
 rulesDependLayerIndex ! CLM option: combination/sub-dividion rules depend on layer index
implicit none
private
public::paramCheck
contains

 ! ************************************************************************************************
 ! (1) new subroutine: check consistency of model parameters
 ! ************************************************************************************************
 subroutine paramCheck(err,message)
 ! model decisions
 USE data_struc,only:model_decisions  ! model decision structure
 USE var_lookup,only:iLookDECISIONS   ! named variables for elements of the decision structure
 ! FUSE data structures
 USE data_struc,only:mpar_data        ! data structures for model parameters
 USE var_lookup,only:iLookPARAM       ! named variables for elements of the data structures
 implicit none
 ! define output
 integer(i4b),intent(out)       :: err         ! error code
 character(*),intent(out)       :: message     ! error message
 ! local variables
 integer(i4b)                   :: iLayer               ! index of model layers
 real(dp),dimension(5)          :: zminLayer            ! minimum layer depth in each layer (m)
 real(dp),dimension(4)          :: zmaxLayer_lower      ! lower value of maximum layer depth 
 real(dp),dimension(4)          :: zmaxLayer_upper      ! upper value of maximum layer depth 
 ! Start procedure here
 err=0; message="paramCheck/"

 ! *****
 ! * check that the snow layer bounds are OK...
 ! ********************************************

 ! select option for combination/sub-division of snow layers
 select case(model_decisions(iLookDECISIONS%snowLayers)%iDecision)
  ! SNTHERM option
  case(sameRulesAllLayers)
   if(mpar_data%var(iLookPARAM%zmax)/mpar_data%var(iLookPARAM%zmin) < 2.5_dp)then
    message=trim(message)//'zmax must be at least 2.5 times larger than zmin: this avoids merging layers that have just been divided'
    err=20; return
   endif
  ! CLM option
  case(rulesDependLayerIndex)
   ! (build vectors of min/max)
   zminLayer       = (/mpar_data%var(iLookPARAM%zminLayer1),&
                       mpar_data%var(iLookPARAM%zminLayer2),&
                       mpar_data%var(iLookPARAM%zminLayer3),&
                       mpar_data%var(iLookPARAM%zminLayer4),&
                       mpar_data%var(iLookPARAM%zminLayer5)/)
   zmaxLayer_lower = (/mpar_data%var(iLookPARAM%zmaxLayer1_lower),&
                       mpar_data%var(iLookPARAM%zmaxLayer2_lower),&
                       mpar_data%var(iLookPARAM%zmaxLayer3_lower),&
                       mpar_data%var(iLookPARAM%zmaxLayer4_lower)/)
   zmaxLayer_upper = (/mpar_data%var(iLookPARAM%zmaxLayer1_upper),&
                       mpar_data%var(iLookPARAM%zmaxLayer2_upper),&
                       mpar_data%var(iLookPARAM%zmaxLayer3_upper),&
                       mpar_data%var(iLookPARAM%zmaxLayer4_upper)/)
  ! (check consistency)
   do iLayer=1,4  ! NOTE: the lower layer does not have a maximum value
    ! ensure that we have higher maximum thresholds for sub-division when fewer number of layers
    if(zmaxLayer_lower(iLayer) < zmaxLayer_upper(iLayer))then
     write(message,'(a,2(i0,a))') trim(message)//'expect the maximum threshold for sub-division in the case where there is only ', &
                                  iLayer,' layer(s) is greater than the maximum threshold for sub-division in the case where there are > ',&
                                  iLayer,' layer(s)'
     err=20; return
    endif
    ! ensure that the maximum thickness is 3 times greater than the minimum thickness
    if(zmaxLayer_upper(iLayer)/zminLayer(iLayer) < 2.5_dp .or. zmaxLayer_upper(iLayer)/zminLayer(iLayer+1) < 2.5_dp)then
     write(message,'(a,3(i0,a))') trim(message)//'zmaxLayer_upper for layer ',iLayer,' must be 2.5 times larger than zminLayer for layers ',&
                                  iLayer,' and ',iLayer+1,': this avoids merging layers that have just been divided'
     err=20; return
    endif
   end do  ! loop through layers
  case default; err=20; message=trim(message)//'unable to identify option to combine/sub-divide snow layers'; return
 end select ! (option to combine/sub-divide snow layers)

 ! -------------------------------------------------------------------------------------------------------------------------------------------

 ! *****
 ! * check soil stress functionality...
 ! ************************************

 ! check that the maximum transpiration limit is within bounds
 if(mpar_data%var(iLookPARAM%critSoilTranspire)>mpar_data%var(iLookPARAM%theta_sat) .or. &
    mpar_data%var(iLookPARAM%critSoilTranspire)<mpar_data%var(iLookPARAM%theta_res))then
  message=trim(message)//'critSoilTranspire parameter is out of range '// &
                         '[NOTE: if overwriting Noah-MP soil table values in paramTrial, must overwrite all soil parameters]'
  err=20; return
 endif

 ! check that the soil wilting point is within bounds
 if(mpar_data%var(iLookPARAM%critSoilWilting)>mpar_data%var(iLookPARAM%theta_sat) .or. &
    mpar_data%var(iLookPARAM%critSoilWilting)<mpar_data%var(iLookPARAM%theta_res))then
  message=trim(message)//'critSoilWilting parameter is out of range '// &
                         '[NOTE: if overwriting Noah-MP soil table values in paramTrial, must overwrite all soil parameters]'
  err=20; return
 endif

 end subroutine paramCheck

end module paramCheck_module