import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Every icon of the app, named by its role, not by its glyph.
///
/// The only file that imports an icon package: a glyph, a stroke weight or
/// the pack itself changes here, never in a widget. Two roles may share a
/// glyph (a playlist and the queue); give each its own entry anyway, so one
/// can change without the other.
///
/// Lucide is the base, at a 300 stroke weight: thinner than its default
/// 400, closer to SF Symbols. Eva gives the filled glyphs Lucide lacks.
abstract final class AppIcons {
  // ── Playback ──────────────────────────────────────────────────────────────
  static const IconData play = LucideIcons300.play;
  static const IconData pause = LucideIcons300.pause;
  static const IconData skipNext = LucideIcons300.skipForward;
  static const IconData skipPrevious = LucideIcons300.skipBack;
  static const IconData shuffle = LucideIcons300.shuffle;
  static const IconData repeat = LucideIcons300.repeat;
  static const IconData repeatOne = LucideIcons300.repeat1;
  static const IconData queue = LucideIcons300.listMusic;
  static const IconData playNext = LucideIcons300.listStart;
  static const IconData addToQueue = LucideIcons300.listEnd;
  static const IconData history = LucideIcons300.history;
  static const IconData sleepTimer = LucideIcons300.timer;
  static const IconData speed = LucideIcons300.gauge;
  static const IconData volumeLow = LucideIcons300.volume1;

  /// On the row of the song that is playing.
  static const IconData nowPlaying = LucideIcons300.music2;

  // ── Library ───────────────────────────────────────────────────────────────
  /// A song, and the placeholder of a song without a cover.
  static const IconData track = LucideIcons300.music;

  /// An album, and the placeholder of an album without a cover.
  static const IconData album = LucideIcons300.disc;

  /// An artist, and the placeholder of an artist without a photo.
  static const IconData artist = LucideIcons300.micVocal;
  static const IconData playlist = LucideIcons300.listMusic;
  static const IconData like = LucideIcons300.heart;
  static const IconData unlike = LucideIcons300.heartOff;

  /// Filled: a song in the liked songs.
  static const IconData liked = EvaIcons.heart;
  static const IconData addToPlaylist = LucideIcons300.listPlus;
  static const IconData removeFromList = LucideIcons300.listX;
  static const IconData lossless = LucideIcons300.audioWaveform;
  static const IconData listen = LucideIcons300.headphones;
  static const IconData artistBio = LucideIcons300.user;
  static const IconData similarArtists = LucideIcons300.users;
  static const IconData releaseDate = LucideIcons300.calendar;
  static const IconData duration = LucideIcons300.clock;
  static const IconData recent = LucideIcons300.clock;
  static const IconData libraryAll = LucideIcons300.galleryVerticalEnd;
  static const IconData libraryScan = LucideIcons300.listMusic;

  // ── Navigation ────────────────────────────────────────────────────────────
  static const IconData home = LucideIcons300.house;
  static const IconData library = LucideIcons300.library;
  static const IconData search = LucideIcons300.search;
  static const IconData settings = LucideIcons300.settings;
  static const IconData back = LucideIcons300.chevronLeft;

  /// Closes Now Playing back into the mini player.
  static const IconData minimize = LucideIcons300.chevronDown;

  /// Leads to another page (a row, a card).
  static const IconData disclosure = LucideIcons300.chevronRight;
  static const IconData expand = LucideIcons300.chevronDown;
  static const IconData collapse = LucideIcons300.chevronUp;
  static const IconData openExternal = LucideIcons300.externalLink;
  static const IconData systemSettings = LucideIcons300.settings2;

  // ── Actions ───────────────────────────────────────────────────────────────
  /// Options of a row.
  static const IconData more = LucideIcons300.ellipsis;

  /// Options of a page, in its header.
  static const IconData moreVertical = LucideIcons300.ellipsisVertical;
  static const IconData close = LucideIcons300.x;

  /// Empties a field.
  static const IconData clear = LucideIcons300.circleX;
  static const IconData add = LucideIcons300.plus;
  static const IconData edit = LucideIcons300.pencil;
  static const IconData delete = LucideIcons300.trash2;
  static const IconData selected = LucideIcons300.check;
  static const IconData dragHandle = LucideIcons300.gripVertical;
  static const IconData sort = LucideIcons300.arrowDownNarrowWide;
  static const IconData listView = LucideIcons300.layoutList;
  static const IconData gridView = LucideIcons300.layoutGrid;
  static const IconData refresh = LucideIcons300.refreshCw;
  static const IconData reset = LucideIcons300.rotateCcw;

  // ── Feedback ──────────────────────────────────────────────────────────────
  static const IconData info = LucideIcons300.info;
  static const IconData error = LucideIcons300.circleAlert;
  static const IconData noResults = LucideIcons300.searchX;
  static const IconData highlight = LucideIcons300.sparkles;
  static const IconData hint = LucideIcons300.sparkle;

  // ── Features and settings ─────────────────────────────────────────────────
  static const IconData stats = LucideIcons300.barChart3;
  static const IconData weeklyRecap = LucideIcons300.calendarHeart;
  static const IconData monthlyReplay = LucideIcons300.calendarSync;
  static const IconData whatsNew = LucideIcons300.sparkles;
  static const IconData update = LucideIcons300.circleArrowUp;
  static const IconData glassEffect = LucideIcons300.sparkles;
  static const IconData pauseOnCall = LucideIcons300.phoneOff;
  static const IconData resumeAfterCall = LucideIcons300.phoneCall;
  static const IconData haptics = LucideIcons300.vibrate;
  static const IconData biographies = LucideIcons300.bookOpen;
  static const IconData photos = LucideIcons300.image;
  static const IconData clearCovers = LucideIcons300.imageOff;
  static const IconData clearOnlineInfo = LucideIcons300.eraser;
  static const IconData backup = LucideIcons300.hardDriveUpload;
  static const IconData restore = LucideIcons300.archiveRestore;
  static const IconData report = LucideIcons300.messageSquareWarning;
  static const IconData privacy = LucideIcons300.shieldCheck;
  static const IconData licenses = LucideIcons300.scrollText;
  static const IconData storageAccess = LucideIcons300.folderLock;
}
