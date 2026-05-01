from django.contrib import admin
from .models import Lecture, Transcript

@admin.register(Lecture)
class LectureAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'created_at')
    search_fields = ('title',)

@admin.register(Transcript)
class TranscriptAdmin(admin.ModelAdmin):
    list_display = ('id', 'lecture', 'language')
    list_filter = ('language',)
    search_fields = ('lecture__title', 'text')
