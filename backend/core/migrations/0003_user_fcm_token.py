from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('core', '0002_userprofilephoto'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='fcm_token',
            field=models.TextField(blank=True, null=True),
        ),
    ]
