from django.db import models

class Lecture(models.Model):
    title = models.CharField(max_length=255)
    audio_file = models.FileField(upload_to='lectures/original/')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

class Transcript(models.Model):
    lecture = models.ForeignKey(Lecture, related_name='transcripts', on_delete=models.CASCADE)
    language = models.CharField(max_length=10)  # e.g., 'en', 'hi', 'gu'
    text = models.TextField()
    audio_file = models.FileField(upload_to='lectures/translated_audio/', null=True, blank=True)

    def __str__(self):
        return f"{self.lecture.title} - {self.language}"
