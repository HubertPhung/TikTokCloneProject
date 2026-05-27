package com.example.tiktokcloneproject.adapters;

import android.content.Context;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.example.tiktokcloneproject.R;
import com.example.tiktokcloneproject.model.Comment;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CommentAdapter extends ArrayAdapter<Comment> {
    private Context context;
    private int resource;
    private List<Comment> objects;
    private String currentUid;
    private FirebaseFirestore db;
    private Map<String, Boolean> likedMap = new HashMap<>(); // Cache user's like status

    public CommentAdapter(@NonNull Context context, int resource, @NonNull List<Comment> objects) {
        super(context, resource, objects);
        this.context = context;
        this.resource = resource;
        this.objects = objects;
        this.currentUid = FirebaseAuth.getInstance().getUid();
        this.db = FirebaseFirestore.getInstance();
    }

    static class ViewHolder {
        ImageView imvAvatar;
        TextView tvUsername;
        TextView tvContent;
        ImageView imvLike;
        TextView tvTotalLikes;
    }

    @NonNull
    @Override
    public View getView(int position, @Nullable View convertView, @NonNull ViewGroup parent) {
        ViewHolder holder;
        if (convertView == null) {
            convertView = LayoutInflater.from(context).inflate(resource, parent, false);
            holder = new ViewHolder();
            holder.imvAvatar = convertView.findViewById(R.id.imvAvatarInComment);
            holder.tvUsername = convertView.findViewById(R.id.txvUsernameInComment);
            holder.tvContent = convertView.findViewById(R.id.txvComment);
            holder.imvLike = convertView.findViewById(R.id.imvLikeInComment);
            holder.tvTotalLikes = convertView.findViewById(R.id.txvTotalLikeComment);
            convertView.setTag(holder);
        } else {
            holder = (ViewHolder) convertView.getTag();
        }

        Comment comment = objects.get(position);
        if (comment == null) return convertView;
        
        String commentId = comment.getCommentId();

        // 1. Init UI with data from model
        holder.tvContent.setText(comment.getContent());
        holder.tvTotalLikes.setText(String.valueOf(comment.getTotalLikes()));
        holder.imvAvatar.setImageResource(R.drawable.default_avatar);
        holder.tvUsername.setText("");
        
        // Tag used to identify view during async loading
        final String currentCommentId = commentId;
        holder.imvLike.setTag(currentCommentId);

        // 2. Load User Profile (Username & Avatar)
        db.collection("profiles").document(comment.getAuthorId())
                .get().addOnSuccessListener(doc -> {
                    if (doc.exists() && currentCommentId.equals(holder.imvLike.getTag())) {
                        holder.tvUsername.setText(doc.getString("username"));
                        String avatarUrl = doc.getString("avatarUrl");
                        if (avatarUrl != null && context != null) {
                            Glide.with(context)
                                    .load(avatarUrl)
                                    .placeholder(R.drawable.default_avatar)
                                    .circleCrop()
                                    .into(holder.imvAvatar);
                        }
                    }
                });

        // 3. Handle Like Status (TikTok Style Toggle)
        boolean isLikedLocally = likedMap.getOrDefault(commentId, false);
        updateLikeUI(holder.imvLike, isLikedLocally);
        
        // If not in cache, fetch from Firestore
        if (currentUid != null && !likedMap.containsKey(commentId)) {
            db.collection("comment_likes").document(commentId)
                    .get().addOnSuccessListener(doc -> {
                        boolean isLiked = doc.exists() && doc.contains(currentUid);
                        likedMap.put(commentId, isLiked);
                        // Check tag again because view might be recycled
                        if (currentCommentId.equals(holder.imvLike.getTag())) {
                            updateLikeUI(holder.imvLike, isLiked);
                        }
                    });
        }

        // 4. Like Click Listener
        holder.imvLike.setOnClickListener(v -> {
            if (currentUid == null) return;

            boolean wasLiked = likedMap.getOrDefault(commentId, false);
            boolean isLikedNow = !wasLiked;
            
            // --- Instant Local Update ---
            likedMap.put(commentId, isLikedNow);
            int newTotal = comment.getTotalLikes() + (isLikedNow ? 1 : -1);
            comment.setTotalLikes(newTotal);
            
            updateLikeUI(holder.imvLike, isLikedNow);
            holder.tvTotalLikes.setText(String.valueOf(newTotal));

            // --- Async Server Update ---
            DocumentReference likeRef = db.collection("comment_likes").document(commentId);
            DocumentReference commentRef = db.collection("comments").document(commentId);

            if (isLikedNow) {
                Map<String, Object> data = new HashMap<>();
                data.put(currentUid, true);
                likeRef.set(data, SetOptions.merge());
                commentRef.update("totalLikes", FieldValue.increment(1));
            } else {
                Map<String, Object> updates = new HashMap<>();
                updates.put(currentUid, FieldValue.delete());
                likeRef.update(updates);
                commentRef.update("totalLikes", FieldValue.increment(-1));
            }
        });

        return convertView;
    }

    private void updateLikeUI(ImageView imv, boolean isLiked) {
        if (isLiked) {
            imv.setImageResource(R.drawable.ic_fill_favorite);
            imv.setColorFilter(Color.parseColor("#FE2C55")); // TikTok Red
        } else {
            imv.setImageResource(R.drawable.ic_like);
            imv.clearColorFilter();
        }
    }
}
