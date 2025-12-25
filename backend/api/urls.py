from django.urls import path
from .views import (
    SignupView, LoginView, UserProfileView, 
    UserSearchView, ConnectionRequestView, ConnectionRespondView, ConnectionListView,
    MomentSendView, MomentListView, MomentReplyView, ActivityListView,
    ConversationListView, ProfilePhotoUploadView, PublicUserProfileView
)

urlpatterns = [
    path('auth/signup/', SignupView.as_view(), name='signup'),
    path('auth/login/', LoginView.as_view(), name='login'),
    path('auth/profile/', UserProfileView.as_view(), name='profile'),
    path('users/search/', UserSearchView.as_view(), name='user-search'),
    path('connections/request/', ConnectionRequestView.as_view(), name='connection-request'),
    path('connections/respond/', ConnectionRespondView.as_view(), name='connection-respond'),
    path('connections/', ConnectionListView.as_view(), name='connection-list'),
    path('moments/send/', MomentSendView.as_view(), name='moment-send'),
    path('moments/', MomentListView.as_view(), name='moment-list'),
    path('moments/reply/', MomentReplyView.as_view(), name='moment-reply'),
    path('activity/', ActivityListView.as_view(), name='activity-list'),
    path('conversations/<int:user_id>/', ConversationListView.as_view(), name='conversation-detail'),
    path('profile/photos/', ProfilePhotoUploadView.as_view(), name='profile-photo-upload'),
    path('profile/photos/<int:photo_id>/', ProfilePhotoUploadView.as_view(), name='profile-photo-delete'),
    path('users/<int:id>/', PublicUserProfileView.as_view(), name='public-user-profile'),
]
