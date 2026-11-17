/// The version of `class-generator`.
///
/// This is the single source of truth for the version reported by the ``ClassGeneratorCommand``
/// and for the release archives. The release workflow verifies that a pushed `vX.Y.Z` tag matches
/// ``current`` before publishing a release.
internal enum Version {

    internal static let current = "1.1.0"

}
