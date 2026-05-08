from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='lecture',
            name='status',
            field=models.CharField(
                choices=[('pending', 'Pending'), ('processing', 'Processing'), ('completed', 'Completed'), ('failed', 'Failed')],
                default='pending',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='lecture',
            name='error_message',
            field=models.TextField(blank=True, default=''),
        ),
        migrations.AlterUniqueTogether(
            name='transcript',
            unique_together={('lecture', 'language')},
        ),
    ]
