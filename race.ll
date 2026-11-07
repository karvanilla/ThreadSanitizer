; ModuleID = 'race.cpp'
source_filename = "race.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx27.0.0"

%"class.std::__1::thread" = type { ptr }
%"class.std::__1::unique_ptr" = type { %struct.anon }
%struct.anon = type { ptr }
%"class.std::__1::unique_ptr.0" = type { %struct.anon.1 }
%struct.anon.1 = type { ptr }

@shared = local_unnamed_addr global i32 0, align 4
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@.str.1 = private unnamed_addr constant [26 x i8] c"thread constructor failed\00", align 1
@llvm.used = appending global [1 x ptr] [ptr @tsan.module_ctor], section "llvm.metadata"
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @tsan.module_ctor, ptr null }]

; Function Attrs: mustprogress nofree norecurse nosync nounwind sanitize_thread ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define void @_Z6writerv() #0 {
  %1 = call ptr @llvm.returnaddress(i32 0)
  call void @__tsan_func_entry(ptr %1)
  call void @__tsan_write4(ptr @shared)
  store i32 42, ptr @shared, align 4, !tbaa !7
  call void @__tsan_func_exit()
  ret void
}

; Function Attrs: mustprogress nofree nounwind sanitize_thread ssp uwtable
define void @_Z6readerv() #1 {
  %1 = call ptr @llvm.returnaddress(i32 0)
  call void @__tsan_func_entry(ptr %1)
  call void @__tsan_read4(ptr @shared)
  %2 = load i32, ptr @shared, align 4, !tbaa !7
  %3 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %2)
  call void @__tsan_func_exit()
  ret void
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr noundef readonly captures(none), ...) local_unnamed_addr #2

; Function Attrs: mustprogress norecurse sanitize_thread ssp uwtable
define noundef i32 @main() local_unnamed_addr #3 personality ptr @__gxx_personality_v0 {
  %1 = call ptr @llvm.returnaddress(i32 0)
  call void @__tsan_func_entry(ptr %1)
  %2 = alloca %"class.std::__1::thread", align 8
  %3 = alloca %"class.std::__1::thread", align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #13
  %4 = invoke ptr @_ZNSt3__16threadC2B9nqe220106IRFvvEJELi0EEEOT_DpOT0_(ptr noundef nonnull %2, ptr noundef nonnull @_Z6writerv)
          to label %5 unwind label %20

5:                                                ; preds = %0
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #13
  %6 = invoke ptr @_ZNSt3__16threadC2B9nqe220106IRFvvEJELi0EEEOT_DpOT0_(ptr noundef nonnull %3, ptr noundef nonnull @_Z6readerv)
          to label %7 unwind label %12

7:                                                ; preds = %5
  invoke void @_ZNSt3__16thread4joinEv(ptr noundef nonnull %2)
          to label %8 unwind label %14

8:                                                ; preds = %7
  invoke void @_ZNSt3__16thread4joinEv(ptr noundef nonnull %3)
          to label %9 unwind label %14

9:                                                ; preds = %8
  %10 = call ptr @_ZNSt3__16threadD1Ev(ptr noundef nonnull %3) #13
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #13
  %11 = call ptr @_ZNSt3__16threadD1Ev(ptr noundef nonnull %2) #13
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #13
  call void @__tsan_func_exit()
  ret i32 0

12:                                               ; preds = %5
  %13 = landingpad { ptr, i32 }
          cleanup
  br label %17

14:                                               ; preds = %8, %7
  %15 = landingpad { ptr, i32 }
          cleanup
  %16 = call ptr @_ZNSt3__16threadD1Ev(ptr noundef nonnull %3) #13
  br label %17

17:                                               ; preds = %14, %12
  %18 = phi { ptr, i32 } [ %15, %14 ], [ %13, %12 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #13
  %19 = call ptr @_ZNSt3__16threadD1Ev(ptr noundef nonnull %2) #13
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #13
  call void @__tsan_func_exit()
  resume { ptr, i32 } %18

20:                                               ; preds = %0
  %21 = landingpad { ptr, i32 }
          cleanup
  call void @__tsan_func_exit()
  resume { ptr, i32 } %21
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #4

declare i32 @__gxx_personality_v0(...)

declare void @_ZNSt3__16thread4joinEv(ptr noundef) local_unnamed_addr #5

; Function Attrs: nounwind
declare ptr @_ZNSt3__16threadD1Ev(ptr noundef returned) unnamed_addr #6

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #4

; Function Attrs: mustprogress sanitize_thread ssp uwtable
define linkonce_odr hidden ptr @_ZNSt3__16threadC2B9nqe220106IRFvvEJELi0EEEOT_DpOT0_(ptr noundef returned %0, ptr noundef nonnull %1) unnamed_addr #7 personality ptr @__gxx_personality_v0 {
  %3 = call ptr @llvm.returnaddress(i32 0)
  call void @__tsan_func_entry(ptr %3)
  %4 = alloca %"class.std::__1::unique_ptr", align 8
  %5 = alloca %"class.std::__1::unique_ptr.0", align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #13
  %6 = invoke noalias nonnull dereferenceable(8) ptr @_Znwm(i64 noundef 8) #15
          to label %7 unwind label %36

7:                                                ; preds = %2
  %8 = invoke ptr @_ZNSt3__115__thread_structC1Ev(ptr noundef nonnull %6)
          to label %9 unwind label %22

9:                                                ; preds = %7
  call void @__tsan_write8(ptr %4)
  store ptr %6, ptr %4, align 8, !tbaa !11
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #13
  %10 = invoke noalias nonnull dereferenceable(16) ptr @_Znwm(i64 noundef 16) #15
          to label %11 unwind label %24

11:                                               ; preds = %9
  call void @__tsan_write8(ptr %4)
  store ptr null, ptr %4, align 8, !tbaa !11
  call void @__tsan_write8(ptr %10)
  store ptr %6, ptr %10, align 8, !tbaa !11
  %12 = getelementptr inbounds nuw i8, ptr %10, i64 8
  call void @__tsan_write8(ptr %12)
  store ptr %1, ptr %12, align 8, !tbaa !16
  call void @__tsan_write8(ptr %5)
  store ptr %10, ptr %5, align 8, !tbaa !18
  %13 = invoke i32 @pthread_create(ptr noundef %0, ptr noundef null, ptr noundef nonnull @_ZNSt3__114__thread_proxyB9nqe220106INS_5tupleIJNS_10unique_ptrINS_15__thread_structENS_14default_deleteIS3_EEEEPFvvEEEEEEPvSA_, ptr noundef nonnull %10)
          to label %14 unwind label %26

14:                                               ; preds = %11
  %15 = icmp eq i32 %13, 0
  br i1 %15, label %16, label %29

16:                                               ; preds = %14
  call void @__tsan_write8(ptr %5)
  store ptr null, ptr %5, align 8, !tbaa !18
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #13
  %17 = load ptr, ptr %4, align 8, !tbaa !11
  call void @__tsan_write8(ptr %4)
  store ptr null, ptr %4, align 8, !tbaa !11
  %18 = icmp eq ptr %17, null
  br i1 %18, label %21, label %19

19:                                               ; preds = %16
  %20 = tail call ptr @_ZNSt3__115__thread_structD1Ev(ptr noundef nonnull %17) #13
  tail call void @_ZdlPv(ptr noundef nonnull %17) #16
  br label %21

21:                                               ; preds = %16, %19
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #13
  call void @__tsan_func_exit()
  ret ptr %0

22:                                               ; preds = %7
  %23 = landingpad { ptr, i32 }
          cleanup
  tail call void @_ZdlPv(ptr noundef %6) #16
  br label %34

24:                                               ; preds = %9
  %25 = landingpad { ptr, i32 }
          cleanup
  br label %31

26:                                               ; preds = %11, %29
  %27 = landingpad { ptr, i32 }
          cleanup
  %28 = call ptr @_ZNSt3__110unique_ptrINS_5tupleIJNS0_INS_15__thread_structENS_14default_deleteIS2_EEEEPFvvEEEENS3_IS8_EEED1B9nqe220106Ev(ptr noundef nonnull %5) #13
  br label %31

29:                                               ; preds = %14
  invoke void @_ZNSt3__120__throw_system_errorEiPKc(i32 noundef %13, ptr noundef nonnull @.str.1) #17
          to label %30 unwind label %26

30:                                               ; preds = %29
  unreachable

31:                                               ; preds = %26, %24
  %32 = phi { ptr, i32 } [ %27, %26 ], [ %25, %24 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #13
  %33 = call ptr @_ZNSt3__110unique_ptrINS_15__thread_structENS_14default_deleteIS1_EEED1B9nqe220106Ev(ptr noundef nonnull %4) #13
  br label %34

34:                                               ; preds = %31, %22
  %35 = phi { ptr, i32 } [ %32, %31 ], [ %23, %22 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #13
  call void @__tsan_func_exit()
  resume { ptr, i32 } %35

36:                                               ; preds = %2
  %37 = landingpad { ptr, i32 }
          cleanup
  call void @__tsan_func_exit()
  resume { ptr, i32 } %37
}

; Function Attrs: nobuiltin allocsize(0)
declare nonnull ptr @_Znwm(i64 noundef) local_unnamed_addr #8

declare ptr @_ZNSt3__115__thread_structC1Ev(ptr noundef returned) unnamed_addr #5

; Function Attrs: nobuiltin nounwind
declare void @_ZdlPv(ptr noundef) local_unnamed_addr #9

; Function Attrs: mustprogress sanitize_thread ssp uwtable
define linkonce_odr hidden ptr @_ZNSt3__114__thread_proxyB9nqe220106INS_5tupleIJNS_10unique_ptrINS_15__thread_structENS_14default_deleteIS3_EEEEPFvvEEEEEEPvSA_(ptr noundef %0) #7 personality ptr @__gxx_personality_v0 {
  %2 = call ptr @llvm.returnaddress(i32 0)
  call void @__tsan_func_entry(ptr %2)
  %3 = alloca %"class.std::__1::unique_ptr.0", align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #13
  call void @__tsan_write8(ptr %3)
  store ptr %0, ptr %3, align 8, !tbaa !18
  %4 = invoke noundef nonnull align 8 dereferenceable(8) ptr @_ZNSt3__119__thread_local_dataEv()
          to label %5 unwind label %24

5:                                                ; preds = %1
  call void @__tsan_read8(ptr %3)
  %6 = load ptr, ptr %3, align 8, !tbaa !18
  %7 = load ptr, ptr %6, align 8, !tbaa !11
  call void @__tsan_write8(ptr %6)
  store ptr null, ptr %6, align 8, !tbaa !11
  call void @__tsan_read8(ptr %4)
  %8 = load i64, ptr %4, align 8, !tbaa !22
  %9 = invoke i32 @pthread_setspecific(i64 noundef %8, ptr noundef %7)
          to label %10 unwind label %24

10:                                               ; preds = %5
  call void @__tsan_read8(ptr %3)
  %11 = load ptr, ptr %3, align 8, !tbaa !18
  %12 = getelementptr inbounds nuw i8, ptr %11, i64 8
  call void @__tsan_read8(ptr %12)
  %13 = load ptr, ptr %12, align 8, !tbaa !25
  invoke void %13()
          to label %14 unwind label %24

14:                                               ; preds = %10
  %15 = load ptr, ptr %3, align 8, !tbaa !18
  call void @__tsan_write8(ptr %3)
  store ptr null, ptr %3, align 8, !tbaa !18
  %16 = icmp eq ptr %15, null
  br i1 %16, label %23, label %17

17:                                               ; preds = %14
  %18 = load ptr, ptr %15, align 8, !tbaa !11
  call void @__tsan_write8(ptr %15)
  store ptr null, ptr %15, align 8, !tbaa !11
  %19 = icmp eq ptr %18, null
  br i1 %19, label %22, label %20

20:                                               ; preds = %17
  %21 = tail call ptr @_ZNSt3__115__thread_structD1Ev(ptr noundef nonnull %18) #13
  tail call void @_ZdlPv(ptr noundef nonnull %18) #16
  br label %22

22:                                               ; preds = %20, %17
  tail call void @_ZdlPv(ptr noundef nonnull %15) #16
  br label %23

23:                                               ; preds = %14, %22
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #13
  call void @__tsan_func_exit()
  ret ptr null

24:                                               ; preds = %10, %5, %1
  %25 = landingpad { ptr, i32 }
          cleanup
  %26 = call ptr @_ZNSt3__110unique_ptrINS_5tupleIJNS0_INS_15__thread_structENS_14default_deleteIS2_EEEEPFvvEEEENS3_IS8_EEED1B9nqe220106Ev(ptr noundef nonnull %3) #13
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #13
  call void @__tsan_func_exit()
  resume { ptr, i32 } %25
}

; Function Attrs: noreturn
declare void @_ZNSt3__120__throw_system_errorEiPKc(i32 noundef, ptr noundef) local_unnamed_addr #10

; Function Attrs: mustprogress nounwind sanitize_thread ssp uwtable
define linkonce_odr hidden ptr @_ZNSt3__110unique_ptrINS_5tupleIJNS0_INS_15__thread_structENS_14default_deleteIS2_EEEEPFvvEEEENS3_IS8_EEED1B9nqe220106Ev(ptr noundef returned %0) unnamed_addr #11 {
  %2 = call ptr @llvm.returnaddress(i32 0)
  call void @__tsan_func_entry(ptr %2)
  %3 = load ptr, ptr %0, align 8, !tbaa !18
  call void @__tsan_write8(ptr %0)
  store ptr null, ptr %0, align 8, !tbaa !18
  %4 = icmp eq ptr %3, null
  br i1 %4, label %11, label %5

5:                                                ; preds = %1
  %6 = load ptr, ptr %3, align 8, !tbaa !11
  call void @__tsan_write8(ptr %3)
  store ptr null, ptr %3, align 8, !tbaa !11
  %7 = icmp eq ptr %6, null
  br i1 %7, label %10, label %8

8:                                                ; preds = %5
  %9 = tail call ptr @_ZNSt3__115__thread_structD1Ev(ptr noundef nonnull %6) #13
  tail call void @_ZdlPv(ptr noundef nonnull %6) #16
  br label %10

10:                                               ; preds = %8, %5
  tail call void @_ZdlPv(ptr noundef nonnull %3) #16
  br label %11

11:                                               ; preds = %1, %10
  call void @__tsan_func_exit()
  ret ptr %0
}

; Function Attrs: mustprogress nounwind sanitize_thread ssp uwtable
define linkonce_odr hidden ptr @_ZNSt3__110unique_ptrINS_15__thread_structENS_14default_deleteIS1_EEED1B9nqe220106Ev(ptr noundef returned %0) unnamed_addr #11 {
  %2 = call ptr @llvm.returnaddress(i32 0)
  call void @__tsan_func_entry(ptr %2)
  %3 = load ptr, ptr %0, align 8, !tbaa !11
  call void @__tsan_write8(ptr %0)
  store ptr null, ptr %0, align 8, !tbaa !11
  %4 = icmp eq ptr %3, null
  br i1 %4, label %7, label %5

5:                                                ; preds = %1
  %6 = tail call ptr @_ZNSt3__115__thread_structD1Ev(ptr noundef nonnull %3) #13
  tail call void @_ZdlPv(ptr noundef nonnull %3) #16
  br label %7

7:                                                ; preds = %1, %5
  call void @__tsan_func_exit()
  ret ptr %0
}

declare i32 @pthread_create(ptr noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #5

declare noundef nonnull align 8 dereferenceable(8) ptr @_ZNSt3__119__thread_local_dataEv() local_unnamed_addr #5

declare i32 @pthread_setspecific(i64 noundef, ptr noundef) local_unnamed_addr #5

; Function Attrs: nounwind
declare ptr @_ZNSt3__115__thread_structD1Ev(ptr noundef returned) unnamed_addr #6

declare void @__tsan_init()

; Function Attrs: nounwind uwtable
define internal void @tsan.module_ctor() #12 {
  call void @__tsan_init()
  ret void
}

; Function Attrs: nounwind
declare void @__tsan_func_entry(ptr) #13

; Function Attrs: nounwind
declare void @__tsan_func_exit() #13

; Function Attrs: nounwind
declare void @__tsan_read4(ptr) #13

; Function Attrs: nounwind
declare void @__tsan_write4(ptr) #13

; Function Attrs: nounwind
declare void @__tsan_read8(ptr) #13

; Function Attrs: nounwind
declare void @__tsan_write8(ptr) #13

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare ptr @llvm.returnaddress(i32 immarg) #14

attributes #0 = { mustprogress nofree norecurse nosync nounwind sanitize_thread ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #1 = { mustprogress nofree nounwind sanitize_thread ssp uwtable "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #2 = { nofree nounwind "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #3 = { mustprogress norecurse sanitize_thread ssp uwtable "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #6 = { nounwind "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #7 = { mustprogress sanitize_thread ssp uwtable "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #8 = { nobuiltin allocsize(0) "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #9 = { nobuiltin nounwind "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #10 = { noreturn "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #11 = { mustprogress nounwind sanitize_thread ssp uwtable "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #12 = { nounwind uwtable "frame-pointer"="non-leaf" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+bti,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a" }
attributes #13 = { nounwind }
attributes #14 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #15 = { builtin allocsize(0) }
attributes #16 = { builtin nounwind }
attributes #17 = { noreturn }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.ident = !{!6}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 27, i32 0]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 1}
!5 = !{i32 4, !"nosanitize_thread", i32 1}
!6 = !{!"Apple clang version 21.0.0 (clang-2100.3.34.2)"}
!7 = !{!8, !8, i64 0}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C++ TBAA"}
!11 = !{!12, !14, i64 0}
!12 = !{!"_ZTSNSt3__110unique_ptrINS_15__thread_structENS_14default_deleteIS1_EEEE", !13, i64 0}
!13 = !{!"_ZTSNSt3__110unique_ptrINS_15__thread_structENS_14default_deleteIS1_EEEUt_E", !14, i64 0}
!14 = !{!"p1 _ZTSNSt3__115__thread_structE", !15, i64 0}
!15 = !{!"any pointer", !9, i64 0}
!16 = !{!17, !15, i64 0}
!17 = !{!"_ZTSNSt3__112__tuple_leafILm1EPFvvELb0EEE", !15, i64 0}
!18 = !{!19, !21, i64 0}
!19 = !{!"_ZTSNSt3__110unique_ptrINS_5tupleIJNS0_INS_15__thread_structENS_14default_deleteIS2_EEEEPFvvEEEENS3_IS8_EEEE", !20, i64 0}
!20 = !{!"_ZTSNSt3__110unique_ptrINS_5tupleIJNS0_INS_15__thread_structENS_14default_deleteIS2_EEEEPFvvEEEENS3_IS8_EEEUt_E", !21, i64 0}
!21 = !{!"p1 _ZTSNSt3__15tupleIJNS_10unique_ptrINS_15__thread_structENS_14default_deleteIS2_EEEEPFvvEEEE", !15, i64 0}
!22 = !{!23, !24, i64 0}
!23 = !{!"_ZTSNSt3__121__thread_specific_ptrINS_15__thread_structEEE", !24, i64 0}
!24 = !{!"long", !9, i64 0}
!25 = !{!15, !15, i64 0}
