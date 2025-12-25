from django.db import models
from django.contrib.auth.models import AbstractUser
import uuid

class User(AbstractUser):
    invite_id = models.CharField(max_length=10, unique=True, blank=True)
    avatar_emoji = models.CharField(max_length=10, default="😊")
    
    def save(self, *args, **kwargs):
        if not self.invite_id:
            self.invite_id = str(uuid.uuid4())[:8].upper()
        super().save(*args, **kwargs)

class Connection(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('ACCEPTED', 'Accepted'),
        ('REJECTED', 'Rejected'),
    )
    requester = models.ForeignKey(User, related_name='sent_connections', on_delete=models.CASCADE)
    receiver = models.ForeignKey(User, related_name='received_connections', on_delete=models.CASCADE)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('requester', 'receiver')

class Moment(models.Model):
    sender = models.ForeignKey(User, related_name='sent_moments', on_delete=models.CASCADE)
    text = models.TextField()
    emoji = models.CharField(max_length=10)
    image = models.ImageField(upload_to='moments/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

class MomentRecipient(models.Model):
    moment = models.ForeignKey(Moment, related_name='recipients', on_delete=models.CASCADE)
    receiver = models.ForeignKey(User, related_name='received_moments', on_delete=models.CASCADE)
    read_at = models.DateTimeField(null=True, blank=True)

class Reply(models.Model):
    parent_moment = models.ForeignKey(Moment, related_name='replies', on_delete=models.CASCADE)
    sender = models.ForeignKey(User, related_name='moment_replies', on_delete=models.CASCADE)
    text = models.TextField()
    emoji = models.CharField(max_length=10, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

class UserProfilePhoto(models.Model):
    user = models.ForeignKey(User, related_name='profile_photos', on_delete=models.CASCADE)
    image = models.ImageField(upload_to='profile_photos/')
    order = models.PositiveSmallIntegerField(default=1) # 1-4
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order']
        unique_together = ('user', 'order')
