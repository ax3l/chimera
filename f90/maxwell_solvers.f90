subroutine maxwell_push_with_spchrg(EG_fb,curr_fb,dens0_fb,dens1_fb,C1,C2,nkx,nkr,nkO)
implicit none
integer, intent(in) :: nkx,nkr,nkO
complex(kind=8),intent(inout) :: EG_fb(nkx,nkr,nkO,6)
complex(kind=8),dimension(nkx,nkr,nkO,3), intent(in) :: curr_fb,dens0_fb,dens1_fb
real (kind=8), intent(in)  :: C1(nkx,nkr,nkO,5),C2(nkx,nkr,nkO,5)

integer         :: l,ikr,iO
complex(kind=8) :: slice_kx(nkx)

!f2py intent(in) :: C1,C2,curr_fb,dens0_fb,dens1_fb
!f2py intent(in,out) :: EG_fb
!f2py intent(hide) :: nkx,nkO,nkr

!$omp parallel shared(EG_fb,curr_fb,dens0_fb,dens1_fb,C1,C2,nkx,nkr,nkO) private(iO)
do iO=1,nkO
  !$omp do schedule(static) private(l,ikr,slice_kx)
  do ikr=1,nkr
    do l=1,3
      slice_kx = C1(:,ikr,iO,1)*EG_fb(:,ikr,iO,l)+C1(:,ikr,iO,2)*EG_fb(:,ikr,iO,3+l)+&
       C1(:,ikr,iO,3)*curr_fb(:,ikr,iO,l)+C1(:,ikr,iO,4)*dens0_fb(:,ikr,iO,l)+C1(:,ikr,iO,5)*dens1_fb(:,ikr,iO,l)
      EG_fb(:,ikr,iO,l+3) = C2(:,ikr,iO,1)*EG_fb(:,ikr,iO,l)+C2(:,ikr,iO,2)*EG_fb(:,ikr,iO,3+l)+&
       C2(:,ikr,iO,3)*curr_fb(:,ikr,iO,l)+C2(:,ikr,iO,4)*dens0_fb(:,ikr,iO,l)+C2(:,ikr,iO,5)*dens1_fb(:,ikr,iO,l)
      EG_fb(:,ikr,iO,l) = slice_kx
    enddo
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine

subroutine maxwell_push_wo_spchrg(EG_fb,curr_fb,C1,C2,nkx,nkr,nkO)
implicit none
integer, intent(in)            :: nkx,nkr,nkO
complex(kind=8), intent(inout) :: EG_fb(nkx,nkr,nkO,6)
complex(kind=8), intent(in)    :: curr_fb(nkx,nkr,nkO,3)
complex(kind=8), intent(in)    :: C1(nkx,nkr,nkO,3),C2(nkx,nkr,nkO,3)

integer         :: l,ikr,iO
complex(kind=8) :: slice_kx(nkx)

!f2py intent(in) :: C1,C2,curr_fb
!f2py intent(in,out) :: EG_fb
!f2py intent(hide) :: nkx,nkO,nkr

!$omp parallel default(shared) private(l,ikr,iO,slice_kx)
do iO=1,nkO
  !$omp do schedule(static)
  do ikr=1,nkr
    do l=1,3
      slice_kx(:) = C1(:,ikr,iO,1)*EG_fb(:,ikr,iO,l)+C1(:,ikr,iO,2)*EG_fb(:,ikr,iO,3+l)+&
       C1(:,ikr,iO,3)*curr_fb(:,ikr,iO,l)
      EG_fb(:,ikr,iO,l+3) = C2(:,ikr,iO,1)*EG_fb(:,ikr,iO,l)+C2(:,ikr,iO,2)*EG_fb(:,ikr,iO,3+l)+&
       C2(:,ikr,iO,3)*curr_fb(:,ikr,iO,l)
      EG_fb(:,ikr,iO,l) = slice_kx(:)
    enddo
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine

subroutine maxwell_init_push(EG_fb,curr_fb,dens1_fb,C1,C2,nkx,nkr,nkO)
implicit none
integer, intent(in) :: nkx,nkr,nkO
complex(kind=8),intent(inout) :: EG_fb(nkx,nkr,nkO,6)
complex(kind=8),dimension(nkx,nkr,nkO,3), intent(in) :: curr_fb,dens1_fb
complex(kind=8), intent(in)  :: C1(nkx,nkr,nkO,2),C2(nkx,nkr,nkO,2)
integer         :: l,ikr,iO

!f2py intent(in) :: C1,C2,curr_fb,dens1_fb
!f2py intent(in,out) :: EG_fb
!f2py intent(hide) :: nkx,nkO,nkr

!$omp parallel shared(EG_fb,curr_fb,dens1_fb,C1,C2,nkx,nkr,nkO) private(iO)
do iO=1,nkO
  !$omp do schedule(static) private(l,ikr)
  do ikr=1,nkr
    do l=1,3
      EG_fb(:,ikr,iO,l)  = EG_fb(:,ikr,iO,l) + C1(:,ikr,iO,1)*curr_fb(:,ikr,iO,l)+C1(:,ikr,iO,2)*dens1_fb(:,ikr,iO,l)
      EG_fb(:,ikr,iO,l+3)= EG_fb(:,ikr,iO,l+3)+C2(:,ikr,iO,1)*curr_fb(:,ikr,iO,l)+C2(:,ikr,iO,2)*dens1_fb(:,ikr,iO,l)
    enddo
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine

subroutine poiss_corr_with_spchrg(vec_fb,vec_fb_aux,vec_fb_aux0,vec_fb_aux1,poiss_fact,dt_inv,nkx,nkr,nkO)
implicit none
integer, intent(in)            :: nkx,nkr,nkO
complex(kind=8), intent(inout) :: vec_fb(nkx,nkr,nkO,3)
complex(kind=8),dimension(nkx,nkr,nkO,3), intent(in) :: vec_fb_aux,vec_fb_aux0,vec_fb_aux1
real(kind=8),    intent(in)    :: poiss_fact(nkx,nkr,nkO),dt_inv
integer         :: l,ikr,iO

!f2py intent(in) :: vec_fb_aux,vec_fb_aux0,vec_fb_aux1,poiss_fact,dt_inv
!f2py intent(in,out) :: vec_fb
!f2py intent(hide) :: nkx,nkO,nkr

!$omp parallel shared(vec_fb,vec_fb_aux,vec_fb_aux0,vec_fb_aux1,poiss_fact,nkx,nkr,nkO,dt_inv) private(iO)
do iO=1,nkO
  !$omp do schedule(static) private(l,ikr)
  do ikr=1,nkr
    do l=1,3
      vec_fb(:,ikr,iO,l) = vec_fb(:,ikr,iO,l) + (vec_fb_aux(:,ikr,iO,l)+&
       (vec_fb_aux1(:,ikr,iO,l)-vec_fb_aux0(:,ikr,iO,l))*dt_inv)*poiss_fact(:,ikr,iO) 
    enddo
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine

subroutine poiss_corr_wo_spchrg(vec_fb,vec_fb_aux,poiss_fact,nkx,nkr,nkO)
implicit none
integer, intent(in)            :: nkx,nkr,nkO
complex(kind=8), intent(inout) :: vec_fb(nkx,nkr,nkO,3)
complex(kind=8), intent(in)    :: vec_fb_aux(nkx,nkr,nkO,3)
real(kind=8),    intent(in)    :: poiss_fact(nkx,nkr,nkO)
integer         :: l,ikr,iO

!f2py intent(in) :: vec_fb_aux,poiss_fact
!f2py intent(in,out) :: vec_fb
!f2py intent(hide) :: nkx,nkO,nkr

!$omp parallel shared(vec_fb,vec_fb_aux,poiss_fact,nkx,nkr,nkO) private(iO)
do iO=1,nkO
  !$omp do schedule(static) private(l,ikr)
  do ikr=1,nkr
    do l=1,3
      vec_fb(:,ikr,iO,l) = vec_fb(:,ikr,iO,l) + vec_fb_aux(:,ikr,iO,l)*poiss_fact(:,ikr,iO)
    enddo
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine

subroutine omp_mult_vec(vec_fb,poiss_fact,nkx,nkr,nkO)
implicit none
integer, intent(in)            :: nkx,nkr,nkO
complex(kind=8), intent(inout) :: vec_fb(nkx,nkr,nkO,3)
real(kind=8),    intent(in)    :: poiss_fact(nkx,nkr,nkO)
integer         :: l,ikr,iO

!f2py intent(in) :: poiss_fact
!f2py intent(in,out) :: vec_fb
!f2py intent(hide) :: nkx,nkO,nkr

!$omp parallel shared(vec_fb,poiss_fact,nkx,nkr,nkO) private(iO)
do iO=1,nkO
  !$omp do schedule(static) private(l,ikr)
  do ikr=1,nkr
    do l=1,3
      vec_fb(:,ikr,iO,l) = vec_fb(:,ikr,iO,l)*poiss_fact(:,ikr,iO)
    enddo
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine

subroutine omp_mult_scl(scl_fb,poiss_fact,nkx,nkr,nkO)
implicit none
integer, intent(in)            :: nkx,nkr,nkO
complex(kind=8), intent(inout) :: scl_fb(nkx,nkr,nkO)
real(kind=8),    intent(in)    :: poiss_fact(nkx,nkr,nkO)
integer         :: l,ikr,iO

!f2py intent(in) :: poiss_fact
!f2py intent(in,out) :: scl_fb
!f2py intent(hide) :: nkx,nkO,nkr

!$omp parallel shared(scl_fb,poiss_fact,nkx,nkr,nkO) private(iO)
do iO=1,nkO
  !$omp do schedule(static) private(l,ikr)
  do ikr=1,nkr
    scl_fb(:,ikr,iO) = scl_fb(:,ikr,iO)*poiss_fact(:,ikr,iO)
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine
