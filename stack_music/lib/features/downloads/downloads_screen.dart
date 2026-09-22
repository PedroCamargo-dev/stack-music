import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/offline/download_store.dart';
import '../../core/offline/offline_downloader.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final store = app.downloadStore;
    final downloader = app.downloader;

    if (store == null || downloader == null) {
      return const Scaffold(
        appBar: _DownloadsAppBar(),
        body: Center(child: Text('Sistema de downloads não inicializado')),
      );
    }

    return ListenableBuilder(
      listenable: downloader,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Downloads'),
          actions: [
            if (store.jobs.isNotEmpty)
              IconButton(
                tooltip: downloader.isPaused
                    ? 'Retomar downloads'
                    : 'Pausar downloads',
                icon: Icon(
                  downloader.isPaused ? Icons.play_arrow : Icons.pause,
                ),
                onPressed: downloader.isPaused
                    ? downloader.resumePending
                    : downloader.pauseActive,
              ),
            if (store.tracks.isNotEmpty)
              IconButton(
                tooltip: 'Remover todos os downloads',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () => _confirmClear(context, downloader),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  store.formatBytes(store.totalDownloadedBytes),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (app.isOffline)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.cloud_off_outlined),
                  title: Text('Modo offline'),
                  subtitle: Text(
                    'Novos downloads ficam na fila até o servidor voltar.',
                  ),
                ),
              ),
            if (store.jobs.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Em andamento',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${store.jobs.length} na fila',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...store.jobs.map(
                (job) => _JobTile(
                  job: job,
                  progress: downloader.progressForJob(job),
                  paused: downloader.isPaused || app.isOffline,
                  onCancel: () => downloader.cancelJob(job.id),
                ),
              ),
              const Divider(height: 32),
            ],
            Text(
              'Baixadas (${store.tracks.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (store.tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Nenhuma música baixada ainda')),
              )
            else
              ...store.tracks.map(
                (track) => _DownloadedTrackTile(
                  track: track,
                  sizeLabel: store.formatBytes(track.fileSize),
                  onRemove: () => downloader.removeDownload(track.trackId),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    OfflineDownloader downloader,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover downloads?'),
        content: const Text(
          'Todas as músicas baixadas serão removidas deste dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover tudo'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await downloader.removeAllDownloads();
    }
  }
}

class _DownloadsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DownloadsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Downloads'));
}

class _JobTile extends StatelessWidget {
  const _JobTile({
    required this.job,
    required this.progress,
    required this.paused,
    required this.onCancel,
  });

  final DownloadJob job;
  final double progress;
  final bool paused;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (job.type) {
      'album' => 'Álbum',
      'playlist' => 'Playlist',
      _ => 'Faixa',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$typeLabel • ${job.trackIds.length} faixas',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onCancel(),
                  tooltip: 'Cancelar',
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress),
            ),
            const SizedBox(height: 4),
            Text(
              paused
                  ? 'Aguardando conexão'
                  : '${(progress * 100).toStringAsFixed(0)}% • Tentativa ${job.attempts + 1}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadedTrackTile extends StatelessWidget {
  const _DownloadedTrackTile({
    required this.track,
    required this.sizeLabel,
    required this.onRemove,
  });

  final DownloadedTrackEntry track;
  final String sizeLabel;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      if (track.artist.isNotEmpty) track.artist,
      if (track.album.isNotEmpty) track.album,
      sizeLabel,
    ].join(' • ');

    return Dismissible(
      key: ValueKey(track.trackId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: ListTile(
        leading: const Icon(Icons.download_done_outlined),
        title: Text(track.title),
        subtitle: Text(metadata),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => onRemove(),
          tooltip: 'Remover download',
        ),
      ),
    );
  }
}
