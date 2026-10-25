// cu_social.dart — CombatUniverse: переход к автору, подписки, лайки,
// сохранения, «поделиться», видео для комбо.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/cu_auth.dart';

const _red = Color(0xFFE5202E);
const _bg = Color(0xFF0E0E10);
const _card = Color(0xFF1A1A1E);
const _muted = Color(0xFF9A9AA3);

void _toast(BuildContext c, String msg, {SnackBarAction? action}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), action: action));
}

// ───────────────────────── Автор ─────────────────────────
class AuthorRef {
  const AuthorRef({
    required this.id,
    required this.name,
    required this.handle,
    this.bio = '',
    this.following = 0,
    this.followers = 0,
    this.likes = 0,
    this.views = 0,
  });

  factory AuthorRef.fromUser(AppUser u) => AuthorRef(
        id: u.id,
        name: u.name,
        handle: u.handle,
        bio: u.bio,
        following: u.following,
        followers: u.followers,
        likes: u.likes,
        views: u.views,
      );

  final String id, name, handle, bio;
  final int following, followers, likes, views;
}

// ───────────────────────── Состояние: подписки / лайки / сохранения ─────────────────────────
class SocialController extends ChangeNotifier {
  final _following = <String>{};
  final _liked = <String>{};
  final _saved = <String>{};

  bool isFollowing(String authorId) => _following.contains(authorId);
  bool isLiked(String itemId) => _liked.contains(itemId);
  bool isSaved(String itemId) => _saved.contains(itemId);

  void toggleFollow(String id) => _toggle(_following, id);
  void toggleLike(String id) => _toggle(_liked, id);
  void toggleSave(String id) => _toggle(_saved, id);

  void _toggle(Set<String> s, String id) {
    s.contains(id) ? s.remove(id) : s.add(id);
    notifyListeners();
  }
}

final social = SocialController();

/// Действия требуют входа. Возвращает true, если пользователь авторизован.
bool requireAuth(BuildContext context) {
  if (auth.signedIn) return true;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return false;
}

// ───────────────────────── Автор-чип (кликабельный) ─────────────────────────
class AuthorChip extends StatelessWidget {
  const AuthorChip({super.key, required this.author, this.showAvatar = true});
  final AuthorRef author;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PublicProfileScreen(author: author))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (showAvatar) ...[
            CircleAvatar(
              radius: 11,
              backgroundColor: _red,
              child: Text(
                  author.name.isEmpty ? '?' : author.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text('Автор: ${author.name}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _red, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Кнопки: лайк / сохранить / поделиться ─────────────────────────
class LikeButton extends StatelessWidget {
  const LikeButton({super.key, required this.itemId, required this.baseCount});

  /// baseCount — число лайков БЕЗ лайка текущего пользователя.
  final String itemId;
  final int baseCount;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: social,
      builder: (_, __) {
        final liked = social.isLiked(itemId);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (requireAuth(context)) {
              HapticFeedback.selectionClick();
              social.toggleLike(itemId);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? _red : _muted, size: 20),
              const SizedBox(width: 4),
              Text('${baseCount + (liked ? 1 : 0)}',
                  style: const TextStyle(color: _muted, fontSize: 13)),
            ]),
          ),
        );
      },
    );
  }
}

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: social,
      builder: (_, __) {
        final saved = social.isSaved(itemId);
        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: saved ? 'Убрать из сохранённых' : 'Сохранить',
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? _red : _muted),
          onPressed: () {
            if (!requireAuth(context)) return;
            social.toggleSave(itemId);
            _toast(context, saved ? 'Убрано из сохранённых' : 'Сохранено');
          },
        );
      },
    );
  }
}

class ShareButton extends StatelessWidget {
  const ShareButton({super.key, required this.link});
  final String link; // например https://combatuniverse.app/combo/<id>

  @override
  Widget build(BuildContext context) => IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Копировать ссылку',
        icon: const Icon(Icons.share_outlined, color: _muted),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: link));
          if (context.mounted) _toast(context, 'Ссылка скопирована');
        },
      );
}

// ───────────────────────── Видео для комбо ─────────────────────────
class VideoLink {
  static final _yt = RegExp(
      r'(?:youtu\.be/|youtube\.com/(?:watch\?v=|shorts/|embed/))([A-Za-z0-9_-]{11})');

  static bool isValid(String url) {
    final u = Uri.tryParse(url.trim());
    return u != null &&
        (u.scheme == 'http' || u.scheme == 'https') &&
        u.host.contains('.');
  }

  static String? youtubeId(String url) => _yt.firstMatch(url)?.group(1);

  static String platform(String url) {
    final h = (Uri.tryParse(url.trim())?.host ?? '').toLowerCase();
    if (h.contains('youtu')) return 'YouTube';
    if (h.contains('tiktok')) return 'TikTok';
    if (h.contains('instagram')) return 'Instagram';
    if (h.contains('twitter') || h == 'x.com' || h.endsWith('.x.com')) {
      return 'X';
    }
    if (h.contains('twitch')) return 'Twitch';
    return 'Видео';
  }
}

/// Превью видео: миниатюра (для YouTube) + кнопка Play → открывает во внешнем приложении.
class VideoPreview extends StatelessWidget {
  const VideoPreview({super.key, required this.url});
  final String url;

  Future<void> _open(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url.trim()));
    if (context.mounted) _toast(context, 'Ссылка скопирована: $url');
  }

  @override
  Widget build(BuildContext context) {
    final id = VideoLink.youtubeId(url);
    return GestureDetector(
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: const Color(0xFF26262B)),
            if (id != null)
              Image.network('https://img.youtube.com/vi/$id/hqdefault.jpg',
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
            Container(color: Colors.black26),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    color: _red, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 36),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 8,
              child: Text(VideoLink.platform(url),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Поле «Добавить видео» для Combo Studio.
class VideoAttachField extends StatefulWidget {
  const VideoAttachField({super.key, this.initial, required this.onChanged});
  final String? initial;
  final ValueChanged<String?> onChanged; // null — видео нет/ссылка некорректна

  @override
  State<VideoAttachField> createState() => _VideoAttachFieldState();
}

class _VideoAttachFieldState extends State<VideoAttachField> {
  late final _c = TextEditingController(text: widget.initial ?? '');

  bool get _valid => VideoLink.isValid(_c.text);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.onChanged(_valid ? _c.text.trim() : null);
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text == null) return;
    _c.text = d!.text!.trim();
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final showError = _c.text.isNotEmpty && !_valid;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _c,
        onChanged: (_) => _changed(),
        keyboardType: TextInputType.url,
        style: const TextStyle(color: Colors.white),
        cursorColor: _red,
        decoration: InputDecoration(
          labelText: 'Видео (YouTube, TikTok, X, Instagram…)',
          labelStyle: const TextStyle(color: _muted),
          errorText: showError ? 'Вставьте корректную ссылку (https://…)' : null,
          prefixIcon: const Icon(Icons.videocam_outlined, color: _muted),
          suffixIcon: _c.text.isEmpty
              ? IconButton(
                  tooltip: 'Вставить',
                  icon: const Icon(Icons.content_paste, color: _muted),
                  onPressed: _paste)
              : IconButton(
                  tooltip: 'Убрать',
                  icon: const Icon(Icons.close, color: _muted),
                  onPressed: () {
                    _c.clear();
                    _changed();
                  }),
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _red, width: 1.5)),
        ),
      ),
      if (_valid) ...[
        const SizedBox(height: 12),
        VideoPreview(url: _c.text),
      ],
    ]);
  }
}

// ───────────────────────── Публичный профиль автора ─────────────────────────
class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({
    super.key,
    required this.author,
    this.comboTab,
    this.buildsTab,
  });

  final AuthorRef author;

  /// Список комбо этого автора (вставь свой список/карточки).
  final Widget Function(AuthorRef author)? comboTab;

  /// Список сборок этого автора.
  final Widget Function(AuthorRef author)? buildsTab;

  bool get _isMe => auth.user?.id == author.id;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          foregroundColor: Colors.white,
          title: Text('@${author.handle}'),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(child: _header(context)),
            const SliverToBoxAdapter(
              child: TabBar(
                indicatorColor: _red,
                labelColor: Colors.white,
                unselectedLabelColor: _muted,
                tabs: [Tab(text: 'Комбо'), Tab(text: 'Сборки')],
              ),
            ),
          ],
          body: TabBarView(children: [
            comboTab?.call(author) ?? const _Empty('Пока нет комбо'),
            buildsTab?.call(author) ?? const _Empty('Пока нет сборок'),
          ]),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: _red,
          child: Text(author.name.isEmpty ? '?' : author.name[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 12),
        Text(author.name,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        Text('@${author.handle}', style: const TextStyle(color: _muted)),
        if (author.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(author.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
        ],
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: social,
          builder: (_, __) {
            final f = social.isFollowing(author.id);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stat('${author.following}', 'Подписки'),
                _stat('${author.followers + (f ? 1 : 0)}', 'Подписчики'),
                _stat('${author.likes}', 'Лайки'),
                _stat('${author.views}', 'Просмотры'),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: _isMe
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _muted),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen())),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Редактировать профиль'),
                )
              : ListenableBuilder(
                  listenable: social,
                  builder: (_, __) {
                    final f = social.isFollowing(author.id);
                    return FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: f ? _card : _red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (requireAuth(context)) social.toggleFollow(author.id);
                      },
                      child: Text(f ? 'Вы подписаны' : 'Подписаться',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Widget _stat(String v, String l) => Column(children: [
        Text(v,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(l, style: const TextStyle(color: _muted, fontSize: 12)),
      ]);
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
      child: Text(text, style: const TextStyle(color: _muted, fontSize: 15)));
}
