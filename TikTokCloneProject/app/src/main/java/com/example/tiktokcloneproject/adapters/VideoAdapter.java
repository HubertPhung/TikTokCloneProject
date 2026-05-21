package com.example.tiktokcloneproject.adapters;

import android.app.Dialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.tiktokcloneproject.R;
import com.example.tiktokcloneproject.activity.CommentActivity;
import com.example.tiktokcloneproject.activity.ProfileActivity;
import com.example.tiktokcloneproject.helper.FirebaseHelper;
import com.example.tiktokcloneproject.helper.GlobalVariable;
import com.example.tiktokcloneproject.helper.OnSwipeTouchListener;
import com.example.tiktokcloneproject.helper.RecommendationHelper;
import com.example.tiktokcloneproject.model.ChatMessage;
import com.example.tiktokcloneproject.model.Report;
import com.example.tiktokcloneproject.model.Video;
import com.google.android.exoplayer2.DefaultLoadControl;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.LoadControl;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.upstream.cache.CacheDataSource;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.ListenerRegistration;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class VideoAdapter extends RecyclerView.Adapter<VideoAdapter.VideoViewHolder> {
    private List<Video> videos;
    private Context context;
    private int currentPosition = 0;
    private final Set<VideoViewHolder> activeHolders = new HashSet<>();
    private FirebaseUser mUser;
    private static boolean isMuted = false;

    public VideoAdapter(Context context, List<Video> videos) {
        this.context = context;
        this.videos = videos;
    }

    public void setUser(FirebaseUser user) {
        mUser = user;
    }

    @NonNull
    @Override
    public VideoViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new VideoViewHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.video_container, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VideoViewHolder holder, int position) {
        holder.setVideoObjects(videos.get(position), position);
    }

    @Override
    public void onBindViewHolder(@NonNull VideoViewHolder holder, int position, @NonNull List<Object> payloads) {
        if (!payloads.isEmpty()) {
            holder.currentVideo = videos.get(position);
        } else {
            super.onBindViewHolder(holder, position, payloads);
        }
    }

    @Override
    public void onViewAttachedToWindow(@NonNull VideoViewHolder holder) {
        activeHolders.add(holder);
        if (holder.getBindingAdapterPosition() == currentPosition) holder.playVideo();
    }

    @Override
    public void onViewDetachedFromWindow(@NonNull VideoViewHolder holder) {
        activeHolders.remove(holder);
        holder.pauseVideo();
    }

    @Override
    public void onViewRecycled(@NonNull VideoViewHolder holder) {
        super.onViewRecycled(holder);
        holder.cleanup();
    }

    @Override
    public int getItemCount() { return videos != null ? videos.size() : 0; }

    public void updateCurrentPosition(int pos) { this.currentPosition = pos; }

    public int getCurrentPosition() { return currentPosition; }
    
    public void pauseVideo(int position) {
        for (VideoViewHolder holder : activeHolders) {
            if (holder.getBindingAdapterPosition() == position) holder.pauseVideo();
        }
    }

    public void playVideo(int position) {
        for (VideoViewHolder holder : activeHolders) {
            if (holder.getBindingAdapterPosition() == position) holder.playVideo();
        }
    }

    public void updateWatchCount(int position) {
        if (position >= 0 && position < videos.size()) {
            RecommendationHelper.recordInterest(videos.get(position).getDescription());
        }
    }

    public class VideoViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener {
        StyledPlayerView videoView;
        ExoPlayer exoPlayer;
        ImageView imvAvatar, imvLike, imvComment, imvShare, imvMore, imvVolume;
        TextView tvComment, tvFavorites, tvTitle, txvDescription, tvHashtags;
        ProgressBar pbLoading;
        String authorId, boundVideoId;
        boolean isLiked = false;
        Video currentVideo;
        ListenerRegistration likeListener, commentListener;

        public VideoViewHolder(@NonNull View itemView) {
            super(itemView);
            videoView = itemView.findViewById(R.id.videoView);
            tvComment = itemView.findViewById(R.id.tvComment);
            tvFavorites = itemView.findViewById(R.id.tvFavorites);
            tvTitle = itemView.findViewById(R.id.tvTitle);
            txvDescription = itemView.findViewById(R.id.txvDescription);
            tvHashtags = itemView.findViewById(R.id.tvHashtags);
            imvAvatar = itemView.findViewById(R.id.imvAvatar);
            imvLike = itemView.findViewById(R.id.imvLike);
            imvComment = itemView.findViewById(R.id.imvComment);
            imvShare = itemView.findViewById(R.id.imvShare);
            imvMore = itemView.findViewById(R.id.imvMore);
            imvVolume = itemView.findViewById(R.id.imvVolume);
            pbLoading = itemView.findViewById(R.id.pbLoading);

            videoView.setOnClickListener(this);
            imvAvatar.setOnClickListener(this);
            imvLike.setOnClickListener(this);
            imvComment.setOnClickListener(this);
            imvShare.setOnClickListener(this);
            imvMore.setOnClickListener(this);
            if (imvVolume != null) imvVolume.setOnClickListener(this);

            videoView.setOnTouchListener(new OnSwipeTouchListener(itemView.getContext()) {
                @Override public void onSwipeLeft() { moveToProfile(authorId); }
            });
        }

        private void initPlayer() {
            if (exoPlayer == null) {
                LoadControl loadControl = new DefaultLoadControl.Builder().setBufferDurationsMs(500, 2000, 500, 500).build();
                DataSource.Factory httpDataSourceFactory = new DefaultHttpDataSource.Factory().setAllowCrossProtocolRedirects(true);
                DataSource.Factory cacheDataSourceFactory = new CacheDataSource.Factory().setCache(GlobalVariable.getVideoCache()).setUpstreamDataSourceFactory(httpDataSourceFactory);
                exoPlayer = new ExoPlayer.Builder(itemView.getContext()).setLoadControl(loadControl).setMediaSourceFactory(new DefaultMediaSourceFactory(cacheDataSourceFactory)).build();
                videoView.setPlayer(exoPlayer);
                exoPlayer.setRepeatMode(Player.REPEAT_MODE_ONE);
                exoPlayer.addListener(new Player.Listener() {
                    @Override public void onPlaybackStateChanged(int state) {
                        if (pbLoading != null) pbLoading.setVisibility(state == Player.STATE_BUFFERING ? View.VISIBLE : View.GONE);
                    }
                });
            }
            updateVolumeUI();
        }

        public void playVideo() { if (exoPlayer != null) exoPlayer.play(); }
        public void pauseVideo() { if (exoPlayer != null) exoPlayer.pause(); }

        public void cleanup() {
            if (exoPlayer != null) { exoPlayer.release(); exoPlayer = null; videoView.setPlayer(null); }
            if (likeListener != null) { likeListener.remove(); likeListener = null; }
            if (commentListener != null) { commentListener.remove(); commentListener = null; }
            boundVideoId = null;
        }

        private void updateLikeUI(boolean liked) {
            imvLike.setImageResource(R.drawable.ic_favorite);
            if (liked) {
                imvLike.setColorFilter(Color.parseColor("#FE2C55")); 
            } else {
                imvLike.setColorFilter(Color.WHITE); 
            }
        }

        private void updateVolumeUI() {
            if (exoPlayer != null) {
                exoPlayer.setVolume(isMuted ? 0f : 1f);
            }
            if (imvVolume != null) {
                imvVolume.setImageResource(isMuted ? R.drawable.ic_baseline_volume_off_24 : R.drawable.ic_baseline_volume_up_24);
            }
        }

        private void toggleVolume() {
            isMuted = !isMuted;
            Toast.makeText(context, isMuted ? "Đã tắt âm" : "Đã bật âm", Toast.LENGTH_SHORT).show();
            for (VideoViewHolder holder : activeHolders) {
                holder.updateVolumeUI();
            }
        }

        public void setVideoObjects(Video video, int position) {
            if (video == null) return;
            this.currentVideo = video;
            this.authorId = video.getAuthorId();
            initPlayer();

            String newUri = video.getVideoUri();
            if (newUri != null) {
                MediaItem currentItem = exoPlayer.getCurrentMediaItem();
                String currentUri = (currentItem != null && currentItem.localConfiguration != null) 
                                    ? currentItem.localConfiguration.uri.toString() : "";
                if (!newUri.equals(currentUri)) {
                    exoPlayer.setMediaItem(MediaItem.fromUri(newUri));
                    exoPlayer.prepare();
                    this.boundVideoId = null;
                }
            }

            if (boundVideoId == null || !boundVideoId.equals(video.getVideoId())) {
                this.boundVideoId = video.getVideoId();
                
                imvAvatar.setImageResource(R.drawable.default_avatar);
                String username = video.getUsername();
                tvTitle.setText(username != null && !username.isEmpty() ? "@" + username : "@User");
                FirebaseFirestore.getInstance().collection("profiles").document(authorId)
                        .get().addOnSuccessListener(doc -> {
                            if (doc.exists() && video.getVideoId().equals(boundVideoId)) {
                                String realUsername = doc.getString("username");
                                String avatarUrl = doc.getString("avatarUrl");
                                if (realUsername != null && !realUsername.isEmpty()) {
                                    tvTitle.setText("@" + realUsername);
                                }
                                if (avatarUrl != null && !avatarUrl.isEmpty() && context != null) {
                                    Glide.with(context).load(avatarUrl).placeholder(R.drawable.default_avatar).circleCrop().into(imvAvatar);
                                }
                            }
                        });

                // Logic tách Hashtag và Description
                String description = video.getDescription();
                StringBuilder hashtagsStr = new StringBuilder();
                String cleanDescription = description != null ? description : "";
                final String REGEX = "#([A-Za-z0-9_\\u00C0-\\u1EF9-]+)";
                List<String> hashtagsList = video.getHashtags();
                if (hashtagsList != null && !hashtagsList.isEmpty()) {
                    for (String tag : hashtagsList) {
                        if (!tag.startsWith("#")) hashtagsStr.append("#");
                        hashtagsStr.append(tag).append(" ");
                    }
                } else if (description != null && description.contains("#")) {
                    Matcher matcher = Pattern.compile(REGEX).matcher(description);
                    while (matcher.find()) { hashtagsStr.append(matcher.group(0)).append(" "); }
                }
                if (hashtagsStr.length() > 0) {
                    tvHashtags.setText(hashtagsStr.toString().trim());
                    tvHashtags.setVisibility(View.VISIBLE);
                    cleanDescription = cleanDescription.replaceAll(REGEX, "").trim();
                } else {
                    tvHashtags.setVisibility(View.GONE);
                }
                txvDescription.setText(cleanDescription.isEmpty() ? (description != null ? description : "") : cleanDescription);

                setupRealtimeListeners(video.getVideoId());
            }
            exoPlayer.setPlayWhenReady(position == currentPosition);
            updateVolumeUI();
        }

        private void setupRealtimeListeners(String vid) {
            if (likeListener != null) likeListener.remove();
            if (commentListener != null) commentListener.remove();
            FirebaseFirestore firestore = FirebaseFirestore.getInstance();
            likeListener = firestore.collection("likes").document(vid).addSnapshotListener((snapshot, error) -> {
                if (snapshot != null && snapshot.exists() && vid.equals(boundVideoId)) {
                    Map<String, Object> data = snapshot.getData();
                    int likesCount = data != null ? data.size() : 0;
                    tvFavorites.setText(String.valueOf(likesCount));
                    String currentUid = FirebaseAuth.getInstance().getCurrentUser() != null ? FirebaseAuth.getInstance().getCurrentUser().getUid() : "";
                    isLiked = !currentUid.isEmpty() && data != null && data.containsKey(currentUid);
                    updateLikeUI(isLiked);
                }
            });
            commentListener = firestore.collection("comments").whereEqualTo("videoId", vid).addSnapshotListener((snapshots, error) -> {
                if (snapshots != null && vid.equals(boundVideoId)) {
                    tvComment.setText(String.valueOf(snapshots.size()));
                }
            });
        }

        @Override public void onClick(View v) {
            int id = v.getId();
            if (id == R.id.videoView) {
                if (exoPlayer != null && exoPlayer.isPlaying()) pauseVideo();
                else playVideo();
            } else if (id == R.id.imvLike) {
                toggleLikeLocal();
            } else if (id == R.id.imvComment) {
                showComments();
            } else if (id == R.id.imvAvatar) {
                moveToProfile(authorId);
            } else if (id == R.id.imvShare) {
                shareDemo();
            } else if (id == R.id.imvMore) {
                showMoreOptions();
            } else if (id == R.id.imvVolume) {
                toggleVolume();
            }
        }

        private void toggleLikeLocal() {
            String currentUid = FirebaseAuth.getInstance().getCurrentUser() != null ? FirebaseAuth.getInstance().getCurrentUser().getUid() : "";
            if (currentUid.isEmpty()) {
                Toast.makeText(context, "Vui lòng đăng nhập!", Toast.LENGTH_SHORT).show();
                return;
            }
            isLiked = !isLiked;
            updateLikeUI(isLiked);
            FirebaseFirestore firestore = FirebaseFirestore.getInstance();
            if (isLiked) {
                Map<String, Object> likeData = new HashMap<>();
                likeData.put(currentUid, true);
                firestore.collection("likes").document(boundVideoId).set(likeData, com.google.firebase.firestore.SetOptions.merge());
            } else {
                Map<String, Object> updates = new HashMap<>();
                updates.put(currentUid, com.google.firebase.firestore.FieldValue.delete());
                firestore.collection("likes").document(boundVideoId).update(updates);
            }
        }

        private void showMoreOptions() {
            String[] options = {"Báo cáo video này", "Lưu video", "Không quan tâm"};
            new AlertDialog.Builder(context).setItems(options, (dialog, which) -> {
                if (which == 0) showReportDialog();
                else Toast.makeText(context, "Tính năng đang phát triển", Toast.LENGTH_SHORT).show();
            }).show();
        }

        private void showReportDialog() {
            String[] reasons = {"Nội dung nhạy cảm", "Spam", "Quấy rối"};
            new AlertDialog.Builder(context).setTitle("Lý do báo cáo").setItems(reasons, (dialog, which) -> submitReport(reasons[which])).show();
        }

        private void submitReport(String reason) {
            FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
            if (user == null) return;
            String reportId = UUID.randomUUID().toString();
            Report report = new Report(reportId, user.getUid(), boundVideoId, "video", reason, currentVideo.getDescription());
            FirebaseFirestore.getInstance().collection("reports").document(reportId).set(report.toMap())
                .addOnSuccessListener(aVoid -> {
                    Toast.makeText(context, "Báo cáo thành công!", Toast.LENGTH_SHORT).show();
                });
        }

        private void showComments() {
            Intent intent = new Intent(context, CommentActivity.class);
            intent.putExtra("videoId", boundVideoId);
            context.startActivity(intent);
        }

        private void moveToProfile(String uid) { 
            Intent intent = new Intent(context, ProfileActivity.class); 
            intent.putExtra("id", uid);
            context.startActivity(intent); 
        }

        private void shareDemo() {
            final Dialog dialog = new Dialog(context);
            dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
            dialog.setContentView(R.layout.share_video_layout);
            dialog.findViewById(R.id.btnCopyURL).setOnClickListener(view -> {
                ClipboardManager cb = (ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
                ClipData data = ClipData.newPlainText("video-link", currentVideo.getVideoUri());
                cb.setPrimaryClip(data);
                Toast.makeText(context, "Link copied", Toast.LENGTH_SHORT).show();
            });
            dialog.findViewById(R.id.txvCancelInSharedPlace).setOnClickListener(view -> dialog.cancel());
            dialog.show();
            Window window = dialog.getWindow();
            if (window != null) {
                window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
                window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
                window.setGravity(Gravity.BOTTOM);
            }
        }
    }
}
