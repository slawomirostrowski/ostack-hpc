!************************************************************
!
!  This example shows how to read and write region references
!  to an attribute.  The program first creates a dataset
!  containing characters and writes references to region of
!  the dataset to a new attribute with a dataspace of DIM0,
!  then closes the file.  Next, it reopens the file,
!  dereferences the references, and outputs the referenced
!  regions to the screen.
!
!  This file is intended for use with HDF5 Library version 1.8
!  with --enable-fortran2003
!
!************************************************************
PROGRAM main

  USE HDF5
  use ISO_C_BINDING

  IMPLICIT NONE

  CHARACTER(LEN=25), PARAMETER :: filename  = "h5ex_t_regrefatt_F03.h5"
  CHARACTER(LEN=3) , PARAMETER :: dataset   = "DS1"
  CHARACTER(LEN=3) , PARAMETER :: dataset2  = "DS2"
  CHARACTER(LEN=3) , PARAMETER :: attribute = "A1"
  INTEGER          , PARAMETER :: dim0      = 2
  INTEGER          , PARAMETER :: ds2dim0   = 16
  INTEGER          , PARAMETER :: ds2dim1   = 3

  INTEGER(HID_T)  :: file, memspace, space, dset, dset2, attr ! Handles
  INTEGER :: hdferr

  INTEGER(HSIZE_T), DIMENSION(1:1)   :: dims = (/dim0/)
  INTEGER(HSIZE_T), DIMENSION(1:1)   :: dims3 
  INTEGER(HSIZE_T), DIMENSION(1:2)   :: dims2 = (/ds2dim0,ds2dim1/)

  INTEGER(HSIZE_T), DIMENSION(1:2,1:4) :: coords = RESHAPE((/2,1,12,3,1,2,5,3/),(/2,4/))
  
  INTEGER(HSIZE_T), DIMENSION(1:2) :: start=(/0,0/),stride=(/11,2/),count=(/2,2/), BLOCK=(/3,1/)

  INTEGER(HSIZE_T), DIMENSION(1:1) :: maxdims
  INTEGER(hssize_t) :: npoints
  TYPE(hdset_reg_ref_t_f), DIMENSION(1:dim0), TARGET :: wdata  ! Write buffer
  TYPE(hdset_reg_ref_t_f), DIMENSION(:), ALLOCATABLE, TARGET :: rdata ! Read buffer

  INTEGER(size_t) :: size
  CHARACTER(LEN=1), DIMENSION(1:ds2dim0,1:ds2dim1), TARGET :: wdata2

  CHARACTER(LEN=80),DIMENSION(1:1), TARGET :: rdata2
  CHARACTER(LEN=80) :: name
  INTEGER :: i
  TYPE(C_PTR) :: f_ptr
  CHARACTER(LEN=ds2dim0) :: chrvar
  !
  ! Initialize FORTRAN interface.
  !
  CALL h5open_f(hdferr)

  chrvar = "The quick brown "
  READ(chrvar,'(16A1)') wdata2(1:16,1)
  chrvar = "fox jumps over  "
  READ(chrvar,'(16A1)') wdata2(1:16,2)
  chrvar = "the 5 lazy dogs "
  READ(chrvar,'(16A1)') wdata2(1:16,3)
  !
  ! Create a new file using the default properties.
  !
  CALL h5fcreate_f(filename, H5F_ACC_TRUNC_F, file, hdferr)
  !
  ! Create a dataset with character data.
  !
  CALL h5screate_simple_f(2, dims2, space, hdferr)
  CALL h5dcreate_f(file,dataset2, H5T_STD_I8LE, space, dset2, hdferr)
  f_ptr = C_LOC(wdata2(1,1))
  CALL h5dwrite_f(dset2, H5T_NATIVE_INTEGER_1, f_ptr, hdferr)
  !
  ! Create reference to a list of elements in dset2.
  !
  CALL h5sselect_elements_f(space, H5S_SELECT_SET_F, 2, INT(4,size_t), coords, hdferr)
  f_ptr = C_LOC(wdata(1))
  CALL h5rcreate_f(file, DATASET2, H5R_DATASET_REGION_F, f_ptr, hdferr, space)
  !
  ! Create reference to a hyperslab in dset2, close dataspace.
  !
  CALL h5sselect_hyperslab_f (space, H5S_SELECT_SET_F, start, count, hdferr, stride, block)
  f_ptr = C_LOC(wdata(2))
  CALL h5rcreate_f(file, DATASET2, H5R_DATASET_REGION_F, f_ptr, hdferr, space)

  CALL h5sclose_f(space, hdferr)
  !
  ! Create dataset with a null dataspace to serve as the parent for
  ! the attribute.
  !
  CALL H5Screate_f(H5S_NULL_F, space, hdferr)
  
  CALL h5dcreate_f(file, dataset, H5T_STD_I32LE, space, dset, hdferr)
  CALL h5sclose_f(space, hdferr)
  !
  ! Create dataspace.  Setting maximum size to the current size.
  !
  CALL h5screate_simple_f(1, dims, space, hdferr)

  !
  ! Create the attribute and write the region references to it.
  !
  CALL H5Acreate_f(dset, attribute, H5T_STD_REF_DSETREG, space, attr, hdferr)
  f_ptr = C_LOC(wdata(1))
  CALL H5Awrite_f(attr, H5T_STD_REF_DSETREG, f_ptr, hdferr)
  !
  ! Close and release resources.
  !
  CALL h5aclose_f(attr , hdferr)
  CALL h5dclose_f(dset , hdferr)
  CALL h5dclose_f(dset2, hdferr)
  CALL h5sclose_f(space, hdferr)
  CALL h5fclose_f(file , hdferr)
  !
  ! Now we begin the read section of this example.
  !
  !
  ! Open file and dataset.
  !
  CALL h5fopen_f(filename, H5F_ACC_RDONLY_F, file, hdferr)
  CALL h5dopen_f(file, dataset, dset, hdferr)
  CALL h5aopen_f(dset, attribute, attr, hdferr)

  !
  ! Get dataspace and allocate memory for read buffer.
  !
  CALL H5Aget_space_f(attr, space, hdferr)
  CALL h5sget_simple_extent_dims_f (space, dims, maxdims, hdferr)
  ALLOCATE(rdata(1:dims(1)))
  CALL h5sclose_f(space, hdferr)
  !
  ! Read the data.
  !
  !   stop
  f_ptr = C_LOC(rdata(1))
  CALL H5Aread_f(attr, H5T_STD_REF_DSETREG, f_ptr, hdferr)
  !
  ! Output the data to the screen.
  !
  DO i = 1, dims(1)
     WRITE(*,'(A,"[",i1,"]:",/,2X,"->")', ADVANCE='NO') attribute, i-1
     !
     ! Open the referenced object, retrieve its region as a
     ! dataspace selection.
     !
     CALL H5Rdereference_f(dset,  rdata(i), dset2, hdferr)
     CALL H5Rget_region_f(dset, rdata(i), space, hdferr)
     !
     ! Get the length of the object's name, allocate space, then
     ! retrieve the name.
     !
     CALL H5Iget_name_f(dset2, name, 80_size_t, size, hdferr)
     !
     ! Allocate space for the read buffer.
     !
     CALL H5Sget_select_npoints_f(space, npoints, hdferr)
     dims3(1) = npoints
     !
     ! Read the dataset region.
     !
     CALL h5screate_simple_f(1, dims3, memspace, hdferr)

     f_ptr = C_LOC(rdata2(1))
     CALL h5dread_f( dset2, H5T_NATIVE_INTEGER_1, f_ptr, hdferr, memspace, space)
     !
     ! Print the name and region data, close and release resources.
     !
     WRITE(*,'(A,": ",A)') name(1:size),rdata2(1)(1:npoints) 
     
     CALL H5Sclose_f(space, hdferr)
     CALL H5Sclose_f(memspace, hdferr)
     CALL H5Dclose_f(dset2, hdferr)

  END DO
  !
  ! Close and release resources.
  !
  DEALLOCATE(rdata)
  CALL H5Aclose_f(attr, hdferr)
  CALL H5Dclose_f(dset, hdferr)
  CALL H5Fclose_f(file, hdferr)

END PROGRAM main
