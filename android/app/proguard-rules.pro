# Room creates generated database implementations by reflection. In R8 full
# mode, keeping only the class name does not retain its no-argument constructor.
# Without this member, WorkManager crashes in its startup ContentProvider,
# before Flutter or Dart can handle the error.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}

# WorkManager also creates its input mergers reflectively when work executes.
-keep class * extends androidx.work.InputMerger {
    <init>();
}
