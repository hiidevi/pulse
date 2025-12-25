from rest_framework import serializers
from django.db.models import Q
from core.models import User, Connection, Moment, Reply, UserProfilePhoto

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'avatar_emoji', 'invite_id', 'password')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            avatar_emoji=validated_data.get('avatar_emoji', '😊')
        )
        return user

class UserProfilePhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfilePhoto
        fields = ('id', 'image', 'order')

class PublicUserSerializer(serializers.ModelSerializer):
    connection_status = serializers.SerializerMethodField()
    profile_photos = UserProfilePhotoSerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'avatar_emoji', 'connection_status', 'profile_photos')

    def get_connection_status(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return 'NONE'
        
        connection = Connection.objects.filter(
            (Q(requester=request.user) & Q(receiver=obj)) | 
            (Q(requester=obj) & Q(receiver=request.user))
        ).first()

        if not connection:
            return 'NONE'
        return connection.status

class ConnectionSerializer(serializers.ModelSerializer):
    requester = UserSerializer(read_only=True)
    receiver = UserSerializer(read_only=True)

    class Meta:
        model = Connection
        fields = '__all__'

class ReplySerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)

    class Meta:
        model = Reply
        fields = '__all__'

class MomentSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    replies = ReplySerializer(many=True, read_only=True)

    class Meta:
        model = Moment
        fields = ('id', 'sender', 'text', 'emoji', 'image', 'created_at', 'replies')
