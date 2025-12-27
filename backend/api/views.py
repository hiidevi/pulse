from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.core.mail import send_mail
from .serializers import (
    UserSerializer, PublicUserSerializer, ConnectionSerializer, 
    MomentSerializer, ReplySerializer, UserProfilePhotoSerializer
)
from core.models import User, Connection, Moment, Reply, MomentRecipient, UserProfilePhoto
from .notifications import send_push_notification

class SignupView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = (permissions.AllowAny,)

    def perform_create(self, serializer):
        user = serializer.save()
        send_mail(
            "Welcome to Pulse! 💓",
            f"Hey {user.username}, welcome to Pulse. Start sharing your heartbeat with those who matter most.",
            "pulseteam@pulse.app",
            [user.email],
            fail_silently=True,
        )

class LoginView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        
        user = User.objects.filter(email=email).first()
        if user and user.check_password(password):
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': UserSerializer(user).data
            })
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

class UserProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    
    def get_object(self):
        return self.request.user

class PublicUserProfileView(generics.RetrieveAPIView):
    queryset = User.objects.all()
    serializer_class = PublicUserSerializer
    lookup_field = 'id'

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context

class UserSearchView(generics.ListAPIView):
    serializer_class = PublicUserSerializer
    
    def get_queryset(self):
        query = self.request.query_params.get('query', '')
        # Search all users except self
        users = User.objects.filter(Q(username__icontains=query) | Q(invite_id__iexact=query)).exclude(id=self.request.user.id)
        return users

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context

class ConnectionRequestView(APIView):
    def post(self, request):
        receiver_id = request.data.get('receiver_id')
        try:
            receiver = User.objects.get(id=receiver_id)
        except (User.DoesNotExist, ValueError):
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Check if any connection exists in either direction
        existing = Connection.objects.filter(
            Q(requester=request.user, receiver=receiver) | 
            Q(requester=receiver, receiver=request.user)
        ).first()

        if existing:
            if existing.status == 'REJECTED':
                existing.status = 'PENDING'
                existing.requester = request.user
                existing.receiver = receiver
                existing.save()
                return Response(ConnectionSerializer(existing).data, status=status.HTTP_200_OK)
            
            if existing.status == 'PENDING' and existing.receiver == request.user:
                # If they sent a request to ME, auto-accept it instead of creating a new one
                existing.status = 'ACCEPTED'
                existing.save()
                return Response(ConnectionSerializer(existing).data, status=status.HTTP_200_OK)
            return Response(ConnectionSerializer(existing).data, status=status.HTTP_200_OK)

        connection = Connection.objects.create(
            requester=request.user,
            receiver=receiver
        )

        # Notify via Email (Mock)
        send_mail(
            "New Circle Request 💓",
            f"Hey {receiver.username}, {request.user.username} wants to join your circle on Pulse! Spark a heartbeat now.",
            "pulseteam@pulse.app",
            [receiver.email],
            fail_silently=True,
        )

        # Send Push Notification
        send_push_notification(
            receiver, 
            "New Circle Request 💓", 
            f"{request.user.username} wants to join your circle! Spark a heartbeat now.",
            {"type": "connection_request", "sender_id": str(request.user.id)}
        )

        return Response(ConnectionSerializer(connection).data, status=status.HTTP_201_CREATED)

class ConnectionRespondView(APIView):
    def post(self, request):
        connection_id = request.data.get('connection_id')
        status_val = request.data.get('status') # ACCEPTED or REJECTED
        try:
            connection = Connection.objects.get(id=connection_id, receiver=request.user)
        except (Connection.DoesNotExist, ValueError):
            return Response({'error': 'Connection request not found'}, status=status.HTTP_404_NOT_FOUND)
            
        connection.status = status_val
        connection.save()
        return Response(ConnectionSerializer(connection).data)

class ConnectionListView(generics.ListAPIView):
    serializer_class = ConnectionSerializer
    
    def get_queryset(self):
        status_filter = self.request.query_params.get('status', 'ACCEPTED')
        if status_filter == 'PENDING':
            # For pending, show only incoming requests for the dashboard
            return Connection.objects.filter(receiver=self.request.user, status='PENDING')
        return Connection.objects.filter(Q(requester=self.request.user) | Q(receiver=self.request.user), status='ACCEPTED')

class MomentSendView(APIView):
    def post(self, request):
        receiver_id = request.data.get('receiver_id')
        try:
            receiver = User.objects.get(id=receiver_id)
        except (User.DoesNotExist, ValueError):
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
        text = request.data.get('text')
        emoji = request.data.get('emoji')
        image = request.FILES.get('image')

        # Verify connection
        if not Connection.objects.filter(
            (Q(requester=request.user) & Q(receiver=receiver)) | 
            (Q(requester=receiver) & Q(receiver=request.user)),
            status='ACCEPTED'
        ).exists():
            return Response({'error': 'Not connected'}, status=status.HTTP_403_FORBIDDEN)
            
        moment = Moment.objects.create(
            sender=request.user,
            text=text,
            emoji=emoji,
            image=image
        )
        # Create recipient entry
        from core.models import MomentRecipient
        MomentRecipient.objects.create(moment=moment, receiver=receiver)
        
        # Notify recipient via Email (Mock)
        send_mail(
            f"Pulse from {request.user.username} 💓",
            f"You've received a new moment: '{text}'. Open Pulse to reveal the heartbeat.",
            "pulseteam@pulse.app",
            [receiver.email],
            fail_silently=True,
        )
        
        # Send Push Notification
        send_push_notification(
            receiver,
            f"Pulse from {request.user.username} 💓",
            f"You've received a new moment: '{text}'.",
            {"type": "moment", "moment_id": str(moment.id), "sender_id": str(request.user.id)}
        )
        
        return Response(MomentSerializer(moment).data, status=status.HTTP_201_CREATED)

class MomentListView(generics.ListAPIView):
    serializer_class = MomentSerializer
    
    def get_queryset(self):
        # Return moments where user is the receiver
        return Moment.objects.filter(recipients__receiver=self.request.user).order_by('-created_at')

class MomentReplyView(APIView):
    def post(self, request):
        parent_moment_id = request.data.get('parent_moment_id')
        text = request.data.get('text')
        emoji = request.data.get('emoji')
        
        try:
            parent_moment = Moment.objects.get(id=parent_moment_id)
        except Moment.DoesNotExist:
            return Response({'error': 'Moment not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Security Check: Is the reply sender a friend of the moment sender?
        # Or is the reply sender the moment sender themselves?
        if not (parent_moment.sender == request.user or 
                Connection.objects.filter(
                    Q(requester=request.user, receiver=parent_moment.sender) | 
                    Q(requester=parent_moment.sender, receiver=request.user),
                    status='ACCEPTED'
                ).exists()):
            return Response({'error': 'Not authorized to reply to this moment'}, status=status.HTTP_403_FORBIDDEN)

        reply = Reply.objects.create(
            parent_moment=parent_moment,
            sender=request.user,
            text=text,
            emoji=emoji
        )
        
        
        # Send Push Notification to Moment Sender
        if parent_moment.sender != request.user:
            send_push_notification(
                parent_moment.sender,
                f"New Reply from {request.user.username} ✨",
                f"'{text}'",
                {"type": "reply", "moment_id": str(parent_moment.id), "sender_id": str(request.user.id)}
            )

        return Response(ReplySerializer(reply).data, status=status.HTTP_201_CREATED)

class ActivityListView(APIView):
    def get(self, request):
        # Unified feed: 
        # 1. New moments sent TO me
        # 2. New replies to moments I SENT
        # 3. New connection requests TO me
        
        moments = Moment.objects.filter(recipients__receiver=request.user).order_by('-created_at')[:10]
        replies = Reply.objects.filter(parent_moment__sender=request.user).exclude(sender=request.user).order_by('-created_at')[:10]
        pending_requests = Connection.objects.filter(receiver=request.user, status='PENDING').order_by('-created_at')[:5]
        
        return Response({
            'moments': MomentSerializer(moments, many=True).data,
            'replies': ReplySerializer(replies, many=True).data,
            'pending_requests': ConnectionSerializer(pending_requests, many=True).data
        })

class ConversationListView(APIView):
    def get(self, request, user_id):
        # Fetch history between request.user and a specific user
        target_user = get_object_or_404(User, id=user_id)
        
        # Security Check: Are they friends?
        if not Connection.objects.filter(
            Q(requester=request.user, receiver=target_user) | 
            Q(requester=target_user, receiver=request.user),
            status='ACCEPTED'
        ).exists():
            return Response({'error': 'You must be in a circle to view history'}, status=status.HTTP_403_FORBIDDEN)

        # Moments sent by either to the other
        sent_moments = Moment.objects.filter(sender=request.user, recipients__receiver=target_user)
        received_moments = Moment.objects.filter(sender=target_user, recipients__receiver=request.user)
        
        moments = (sent_moments | received_moments).distinct().order_by('created_at')
        
        return Response(MomentSerializer(moments, many=True).data)

class ProfilePhotoUploadView(APIView):
    def post(self, request):
        image = request.FILES.get('image')
        order = request.data.get('order', 1) # 1-4
        
        if not image:
            return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            order = int(order)
            if order < 1 or order > 4:
                return Response({'error': 'Order must be between 1 and 4'}, status=status.HTTP_400_BAD_REQUEST)
        except ValueError:
            return Response({'error': 'Invalid order'}, status=status.HTTP_400_BAD_REQUEST)

        # Update or create
        photo, created = UserProfilePhoto.objects.update_or_create(
            user=request.user,
            order=order,
            defaults={'image': image}
        )
        
        return Response(UserProfilePhotoSerializer(photo).data, status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED)
    
    def delete(self, request, photo_id):
        photo.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

class FCMTokenRegisterView(APIView):
    def post(self, request):
        token = request.data.get('fcm_token')
        if not token:
            return Response({'error': 'No token provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        request.user.fcm_token = token
        request.user.save()
        return Response({'status': 'Token registered successfully'})
