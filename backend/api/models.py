from django.db import models

class Lecture(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    ]

    title = models.CharField(max_length=255)
    audio_file = models.FileField(upload_to='lectures/original/')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    error_message = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} ({self.status})"

class Transcript(models.Model):
    lecture = models.ForeignKey(Lecture, related_name='transcripts', on_delete=models.CASCADE)
    language = models.CharField(max_length=10)  # e.g., 'en', 'hi', 'gu'
    text = models.TextField()
    audio_file = models.FileField(upload_to='lectures/translated_audio/', null=True, blank=True)

    class Meta:
        unique_together = ('lecture', 'language')

    def __str__(self):
        return f"{self.lecture.title} - {self.language}"
