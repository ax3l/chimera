subroutine dep_curr_chnk(coord,momenta,wghts,curr,IndInChunk,guards,leftX,Rgrid,dx_inv,dr_inv,&
                    np,nx,nr,nkO,nchnk)
use omp_lib
implicit none
integer, intent(in)        :: np,nx,nr,nkO,nchnk,IndInChunk(0:nchnk),guards
real (kind=8), intent(in)  :: coord(3,np),momenta(3,np),wghts(np),leftX,Rgrid(0:nr),&
                              dx_inv,dr_inv
complex(kind=8),intent(inout):: curr(0:nx,0:nr,0:nkO,3)
integer         :: ix,ir,ip,k,l,iO,nxleft,chunk_size,ichnk
real(kind=8)    :: xp,yp,zp,rp,gp,wp,S0(0:1,2),veloc(3),curr_p(0:1,0:1),inv9
complex(kind=8) :: ii=(0.0d0,1.0d0),phaseO(0:nkO),phase_m
complex(kind=8), allocatable :: loc_left(:,:,:,:),loc_right(:,:,:,:)

!f2py intent(in) :: coord,momenta,wghts,IndInChunk,guards,leftX,Rgrid,dx_inv,dr_inv
!f2py intent(in,out) :: curr
!f2py intent(hide) :: np,nx,nr,nkO,nchnk

chunk_size=(nx+1)/nchnk
call omp_set_num_threads(nchnk)

inv9 = 1.0d0/9.0d0

!$omp parallel default(shared) &
!$omp private(loc_left,loc_right,xp,yp,zp,rp,wp,gp,S0,&
!$omp   veloc,curr_p,phaseO,phase_m,ix,ir,ip,k,l,iO,ichnk,nxleft)

ichnk = omp_get_thread_num()
allocate(loc_left(-guards:0,0:nr,0:nkO,3))
allocate(loc_right(chunk_size:chunk_size+guards,0:nr,0:nkO,3))

nxleft = ichnk*chunk_size
loc_left = 0.  
loc_right = 0.  

do ip=IndInChunk(ichnk)+1,IndInChunk(ichnk+1)
  wp = wghts(ip)
  if(wp == 0.0) CYCLE
  xp = coord(1,ip)
  yp = coord(2,ip)
  zp = coord(3,ip)
  veloc = momenta(:,ip)
  rp = DSQRT(yp*yp+zp*zp)
  if ((rp>=Rgrid(nr)) .or. (SUM(ABS(veloc)).eq. 0.0d0)) CYCLE
  gp = DSQRT(1+veloc(1)*veloc(1)+veloc(2)*veloc(2)+veloc(3)*veloc(3))
  veloc = veloc*wp/gp

  ix = FLOOR((xp-leftX)*dx_inv)-nxleft
  ir = FLOOR((rp-Rgrid(0))*dr_inv)

  S0 = 0.0d0
  S0(1,1) = (xp-leftX)*dx_inv - ix - nxleft
  S0(0,1) = 1.0d0 -S0(1,1)
  S0(1,2) = (rp-Rgrid(ir))*dr_inv
  S0(0,2) = 1.0d0 -S0(1,2)

  if (rp>0.0) then
    phase_m = (yp-ii*zp)/rp
  else
    phase_m = 0.0d0
  endif

  phaseO(0) = 1.0d0
  if (nkO>0) then
    do iO = 1,nkO
      phaseO(iO) = phaseO(iO-1)*phase_m
    enddo
  endif

  do k = 0,1
    curr_p(:,k) = S0(:,1)*S0(k,2)
  enddo

  do l=1,3
    do iO = 0,nkO
      do k = 0,1
        if (ix+k<=0) then
          loc_left(ix+k,ir:ir+1,iO,l) = loc_left(ix+k,ir:ir+1,iO,l)+phaseO(iO)*veloc(l)*curr_p(k,:)
        elseif (ix+k>=chunk_size) then
          loc_right(ix+k,ir:ir+1,iO,l)=loc_right(ix+k,ir:ir+1,iO,l)+phaseO(iO)*veloc(l)*curr_p(k,:)
        else
          curr(ix+nxleft+k,ir:ir+1,iO,l)=curr(ix+nxleft+k,ir:ir+1,iO,l)+phaseO(iO)*veloc(l)*curr_p(k,:)
        endif
      enddo
    enddo
  enddo
enddo

if (nxleft+chunk_size+guards<=nx) then
  curr(nxleft+chunk_size:nxleft+chunk_size+guards,:,:,:) = &
   curr(nxleft+chunk_size:nxleft+chunk_size+guards,:,:,:) + loc_right
endif
!$omp barrier
if (nxleft-guards>=0) then
  curr(nxleft-guards:nxleft,:,:,:) = &
   curr(nxleft-guards:nxleft,:,:,:) + loc_left
endif
deallocate(loc_left)
deallocate(loc_right)
!$omp end parallel

!$omp parallel do schedule(static) default(shared) private(ix,iO,l)
do l=1,3
  do ix=0,nx
    curr(ix,1,0,l) = curr(ix,1,0,l) + curr(ix,0,0,l)
  enddo

  if (nkO>0) then
    do iO = 1,nkO
      do ix=0,nx
        curr(ix,1,iO,l) = curr(ix,2,iO,l)*inv9
      enddo
    enddo
  endif
enddo
!$omp end parallel do

!  curr(:,1,1:nkO,:) = curr(:,2,1:nkO,:)*inv9
!endif
curr(:,0,:,:) = 0.0

end subroutine

subroutine dep_dens_chnk(coord,wghts,dens,IndInChunk,guards,leftX,Rgrid,dx_inv,dr_inv,&
                    np,nx,nr,nkO,nchnk)
use omp_lib
implicit none
integer, intent(in)        :: np,nx,nr,nkO,nchnk,IndInChunk(0:nchnk),guards
real (kind=8), intent(in)  :: coord(3,np),wghts(np),leftX,Rgrid(0:nr),&
                              dx_inv,dr_inv
complex(kind=8),intent(inout):: dens(0:nx,0:nr,0:nkO)
integer         :: ix,ir,ip,k,iO,nxleft,chunk_size,ichnk
real(kind=8)    :: xp,yp,zp,rp,wp,S0(0:1,2), dens_p(0:1,0:1)
complex(kind=8) :: ii=(0.0d0,1.0d0),phaseO(0:nkO),phase_m
complex(kind=8), allocatable :: loc_left(:,:,:), loc_right(:,:,:)
!f2py intent(in) :: coord,wghts,IndInChunk,guards,leftX,Rgrid,dx_inv,dr_inv
!f2py intent(in,out) :: dens
!f2py intent(hide) :: np,nx,nr,nkO,nchnk

chunk_size=(nx+1)/nchnk
call omp_set_num_threads(nchnk)

!$omp parallel default(shared) &
!$omp private(loc_left,loc_right,xp,yp,zp,rp,wp,S0,dens_p,phaseO,phase_m,&
!$omp  ix,ir,ip,k,iO,ichnk,nxleft)
allocate(loc_left(-guards:0,0:nr,0:nkO))
allocate(loc_right(chunk_size:chunk_size+guards,0:nr,0:nkO))
ichnk = omp_get_thread_num()

nxleft = ichnk*chunk_size
loc_left = 0.0d0
loc_right= 0.0d0

do ip=IndInChunk(ichnk)+1,IndInChunk(ichnk+1)
  wp = wghts(ip)
  if (wp == 0.0) CYCLE
  xp = coord(1,ip)
  yp = coord(2,ip)
  zp = coord(3,ip)
  rp = DSQRT(yp*yp+zp*zp)
  if (rp>=Rgrid(nr)) CYCLE

  ix = FLOOR((xp-leftX)*dx_inv)-nxleft
  ir = FLOOR((rp-Rgrid(0))*dr_inv)

  S0 = 0.0d0
  S0(1,1) = (xp-leftX)*dx_inv-nxleft - ix
  S0(0,1) = 1.0d0 -S0(1,1)
  S0(1,2) = (rp-Rgrid(ir))*dr_inv
  S0(0,2) = 1.0d0 -S0(1,2)

  if (rp>0.0) then
    phase_m = (yp-ii*zp)/rp
  else
    phase_m = 0.0d0
  endif

  phaseO(0) = 1.0d0
  if (nkO>0) then
    do iO = 1,nkO
      phaseO(iO) = phaseO(iO-1)*phase_m
    enddo
  endif

  do k = 0,1
    dens_p(:,k) = S0(:,1)*S0(k,2)*wp
  enddo

  do iO = 0,nkO
    do k = 0,1
      if (ix+k<=0) then
        loc_left(ix+k,ir:ir+1,iO) = loc_left(ix+k,ir:ir+1,iO)+phaseO(iO)*dens_p(k,:)
      elseif (ix+k>=chunk_size) then
        loc_right(ix+k,ir:ir+1,iO) = loc_right(ix+k,ir:ir+1,iO)+phaseO(iO)*dens_p(k,:)
      else
        dens(ix+nxleft+k,ir:ir+1,iO) = dens(ix+nxleft+k,ir:ir+1,iO)+ phaseO(iO)*dens_p(k,:)
      endif
    enddo
  enddo
enddo

if (nxleft+chunk_size+guards<=nx) then
  dens(nxleft+chunk_size:nxleft+chunk_size+guards,:,:) = &
   dens(nxleft+chunk_size:nxleft+chunk_size+guards,:,:) + loc_right
endif
!$omp barrier
if (nxleft-guards>=0) then
  dens(nxleft-guards:nxleft,:,:) = &
   dens(nxleft-guards:nxleft,:,:) + loc_left 
endif

deallocate(loc_left)
deallocate(loc_right)
!$omp end parallel

dens(:,1,:) = dens(:,1,:) - dens(:,0,:)
dens(:,0,:) = 0.0
end subroutine

subroutine dep_curr_env_chnk(coord,momenta,wghts,curr,IndInChunk,guards,leftX,Rgrid,dx_inv,dr_inv,&
                    kx0,np,nx,nr,nkO,nchnk)
use omp_lib
implicit none
integer, intent(in)       :: np,nx,nr,nkO,nchnk,IndInChunk(0:nchnk),guards
real (kind=8), intent(in) :: coord(3,np),momenta(3,np),wghts(np),leftX,Rgrid(0:nr),&
                             dx_inv,dr_inv,kx0
complex(kind=8),intent(inout) :: curr(0:nx,0:nr,-nkO:nkO,3)
integer                      :: ix,ir,ip,k,l,iO,ichnk,nxleft,chunk_size
real(kind=8)                 :: xp,yp,zp,rp,gp,S0(0:1,2),veloc(3)
complex(kind=8)              :: ii=(0.0d0,1.0d0),curr_p(0:1,0:1),phaseO(0:nkO),phase_m,wp
complex(kind=8), allocatable :: loc_left(:,:,:,:),loc_right(:,:,:,:)

!f2py intent(in) :: coord,momenta,wghts,IndInChunk,guards,leftX,Rgrid,dx_inv,dr_inv,kx0
!f2py intent(in,out) :: curr
!f2py intent(hide) :: np,nx,nr,nkO,nchnk

chunk_size=(nx+1)/nchnk
call omp_set_num_threads(nchnk)

!$omp parallel default(shared) &
!$omp private(loc_left,loc_right,xp,yp,zp,rp,gp,wp,S0,veloc,curr_p,phaseO,phase_m,&
!$omp  ix,ir,ip,k,l,iO,ichnk,nxleft)
ichnk = omp_get_thread_num()
allocate(loc_left(-guards:0,0:nr,-nkO:nkO,3))
allocate(loc_right(chunk_size:chunk_size+guards,0:nr,-nkO:nkO,3))

nxleft = ichnk*chunk_size
loc_left = 0.
loc_right = 0.

do ip=IndInChunk(ichnk)+1,IndInChunk(ichnk+1)
  wp = wghts(ip)
  if(wp == 0.0) CYCLE
  xp = coord(1,ip)
  yp = coord(2,ip)
  zp = coord(3,ip)
  rp = DSQRT(yp*yp+zp*zp)
  veloc = momenta(:,ip)
  if ((rp>=Rgrid(nr)) .or. (SUM(ABS(veloc)).eq. 0.0d0)) CYCLE
  gp = DSQRT(1+veloc(1)*veloc(1)+veloc(2)*veloc(2)+veloc(3)*veloc(3))

  veloc = veloc/gp
  wp = wp*(dcos(xp*kx0) - ii*dsin(xp*kx0))

  ix = FLOOR((xp-leftX)*dx_inv)-nxleft
  ir = FLOOR((rp-Rgrid(0))*dr_inv)

  S0 = 0.0d0
  S0(1,1) = (xp-leftX)*dx_inv - ix-nxleft
  S0(0,1) = 1.0d0 -S0(1,1)
  S0(1,2) = (rp-Rgrid(ir))*dr_inv
  S0(0,2) = 1.0d0 -S0(1,2)

  if (rp>0.0) then
    phase_m = (yp-ii*zp)/rp
  else
    phase_m = 0.0d0
  endif

  phaseO(0) = 1.0
  if (nkO>0) then
    do iO = 1,nkO
      phaseO(iO) = phaseO(iO-1)*phase_m
    enddo
  endif

  do k = 0,1
    curr_p(:,k) = S0(:,1)*S0(k,2)
  enddo
  curr_p = curr_p*wp

  do l=1,3
    do iO = 0,nkO
      do k = 0,1
        if (ix+k<=0) then
          loc_left(ix+k,ir:ir+1,iO,l) = loc_left(ix+k,ir:ir+1,iO,l)+phaseO(iO)*veloc(l)*curr_p(k,:)
          if (iO>0) loc_left(ix+k,ir:ir+1,-iO,l) = loc_left(ix+k,ir:ir+1,-iO,l)+ &
            CONJG(phaseO(iO))*veloc(l)*curr_p(k,:)
        elseif (ix+k>=chunk_size) then
          loc_right(ix+k,ir:ir+1,iO,l)=loc_right(ix+k,ir:ir+1,iO,l)+phaseO(iO)*veloc(l)*curr_p(k,:)
          if (iO>0) loc_right(ix+k,ir:ir+1,-iO,l) = loc_right(ix+k,ir:ir+1,-iO,l)+ &
            CONJG(phaseO(iO))*veloc(l)*curr_p(k,:)
        else
          curr(ix+nxleft+k,ir:ir+1,iO,l)=curr(ix+nxleft+k,ir:ir+1,iO,l)+phaseO(iO)*veloc(l)*curr_p(k,:)
          if (iO>0) curr(ix+nxleft+k,ir:ir+1,-iO,l) = curr(ix+nxleft+k,ir:ir+1,-iO,l)+ &
            CONJG(phaseO(iO))*veloc(l)*curr_p(k,:)
        endif
      enddo
    enddo
  enddo
enddo

if (nxleft+chunk_size+guards<=nx) then
  curr(nxleft+chunk_size:nxleft+chunk_size+guards,:,:,:) = &
   curr(nxleft+chunk_size:nxleft+chunk_size+guards,:,:,:) + loc_right
endif
!$omp barrier
if (nxleft-guards>=0) then
  curr(nxleft-guards:nxleft,:,:,:) = &
   curr(nxleft-guards:nxleft,:,:,:) + loc_left
endif
!$omp barrier
deallocate(loc_left)
deallocate(loc_right)
!$omp end parallel
 
if (Rgrid(0)<0) then
  curr(:,1,nkO,:) = curr(:,1,nkO,:) + curr(:,0,nkO,:)
  if (nkO>0) then
    curr(:,1,1:nkO,:) = curr(:,2,1:nkO,:)/9.0d0
    curr(:,1,-nkO:-1,:) = curr(:,2,-nkO:-1,:)/9.0d0
  endif
  curr(:,0,:,:) = 0.0
endif

end subroutine

subroutine dep_dens_env_chnk(coord,wghts,dens,IndInChunk,guards,leftX,Rgrid,dx_inv,dr_inv,&
                    kx0,np,nx,nr,nkO,nchnk)
use omp_lib
implicit none
integer, intent(in)        :: np,nx,nr,nkO,nchnk,IndInChunk(0:nchnk),guards
real (kind=8), intent(in)  :: coord(3,np),wghts(np),leftX,Rgrid(0:nr),&
                              dx_inv,dr_inv,kx0
complex(kind=8),intent(inout):: dens(0:nx,0:nr,-nkO:nkO)
integer         :: ix,ir,ip,k,iO,ichnk,nxleft,chunk_size
real(kind=8)    :: xp,yp,zp,rp,S0(0:1,2)
complex(kind=8) :: ii=(0.0d0,1.0d0),dens_p(0:1,0:1),phaseO(0:nkO),phase_m,wp
complex(kind=8), allocatable :: loc_left(:,:,:),loc_right(:,:,:)

!f2py intent(in) :: coord,wghts,IndInChunk,guards,leftX,Rgrid,dx_inv,dr_inv,kx0
!f2py intent(in,out) :: dens
!f2py intent(hide) :: np,nx,nr,nkO,nchnk

chunk_size=(nx+1)/nchnk
call omp_set_num_threads(nchnk)

!$omp parallel default(shared) &
!$omp private(loc_left,loc_right,xp,yp,zp,rp,wp,S0,dens_p,phaseO,phase_m,ix,ir,ip,k,iO,ichnk,nxleft)
ichnk = omp_get_thread_num()
allocate(loc_left(-guards:0,0:nr,-nkO:nkO))
allocate(loc_right(chunk_size:chunk_size+guards,0:nr,-nkO:nkO))

nxleft = ichnk*chunk_size
loc_left = 0.
loc_right = 0.

do ip=IndInChunk(ichnk)+1,IndInChunk(ichnk+1)
  wp = wghts(ip)
  if(wp == 0.0) CYCLE
  xp = coord(1,ip)
  yp = coord(2,ip)
  zp = coord(3,ip)
  rp = DSQRT(yp*yp+zp*zp)
  if(rp>=Rgrid(nr)) CYCLE

  wp = wp*(dcos(xp*kx0) - ii*dsin(xp*kx0))
  ix = FLOOR((xp-leftX)*dx_inv)-nxleft
  ir = FLOOR((rp-Rgrid(0))*dr_inv)

  S0 = 0.0d0
  S0(1,1) = (xp-leftX)*dx_inv - ix-nxleft
  S0(0,1) = 1.0d0 -S0(1,1)
  S0(1,2) = (rp-Rgrid(ir))*dr_inv
  S0(0,2) = 1.0d0 -S0(1,2)

  if (rp>0.0) then
    phase_m = (yp-ii*zp)/rp
  else
    phase_m = 0.0d0
  endif

  phaseO(0) = 1.0
  if (nkO>0) then
    do iO = 1,nkO
      phaseO(iO) = phaseO(iO-1)*phase_m
    enddo
  endif

  do k = 0,1
    dens_p(:,k) = S0(:,1)*S0(k,2)*wp
  enddo
  dens_p = dens_p*wp

  do iO = 0,nkO
    do k = 0,1
      if (ix+k<=0) then
        loc_left(ix+k,ir:ir+1,iO) = loc_left(ix+k,ir:ir+1,iO)+phaseO(iO)*dens_p(k,:)
        if (iO>0) loc_left(ix+k,ir:ir+1,-iO) = loc_left(ix+k,ir:ir+1,-iO)+ &
          CONJG(phaseO(iO))*dens_p(k,:)
      elseif (ix+k>=chunk_size) then
        loc_right(ix+k,ir:ir+1,iO)=loc_right(ix+k,ir:ir+1,iO)+phaseO(iO)*dens_p(k,:)
        if (iO>0) loc_right(ix+k,ir:ir+1,-iO) = loc_right(ix+k,ir:ir+1,-iO)+ &
          CONJG(phaseO(iO))*dens_p(k,:)
      else
        dens(ix+nxleft+k,ir:ir+1,iO)=dens(ix+nxleft+k,ir:ir+1,iO)+phaseO(iO)*dens_p(k,:)
        if (iO>0) dens(ix+nxleft+k,ir:ir+1,-iO) = dens(ix+nxleft+k,ir:ir+1,-iO)+ &
          CONJG(phaseO(iO))*dens_p(k,:)
      endif
    enddo
  enddo
enddo

if (nxleft+chunk_size+guards<=nx) then
  dens(nxleft+chunk_size:nxleft+chunk_size+guards,:,:) = &
   dens(nxleft+chunk_size:nxleft+chunk_size+guards,:,:) + loc_right
endif
!$omp barrier
if (nxleft-guards>=0) then
  dens(nxleft-guards:nxleft,:,:) = &
   dens(nxleft-guards:nxleft,:,:) + loc_left
endif
deallocate(loc_left)
deallocate(loc_right)
!$omp end parallel

if (Rgrid(0)<0) then
  dens(:,1,:) = dens(:,1,:) - dens(:,0,:)
  dens(:,0,:) = 0.0
endif

end subroutine
