package main

import (
	"bufio"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

type DownloadStats struct {
	TotalProcessed  int `json:"total_processed"`
	TotalDownloaded int `json:"total_downloaded"`
	TotalSkipped    int `json:"total_skipped"`
}

type SpotifyToken struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   int    `json:"expires_in"`
}

type ProcessUrlsRequest struct {
	URLs []string `json:"urls"`
}

// TrackInfo continua exatamente como antes:
type TrackInfo struct {
	URL        string `json:"url"`
	Title      string `json:"title"`
	Platform   string `json:"platform"`
	Type       string `json:"type"`
	Duration   string `json:"duration,omitempty"`
	Thumbnail  string `json:"thumbnail,omitempty"`
	TrackCount *int   `json:"track_count,omitempty"`
}

// Agora a resposta inclui 4 slices, uma para cada tipo:
type ProcessUrlsResponse struct {
	Tracks    []TrackInfo `json:"tracks,omitempty"`
	Playlists []TrackInfo `json:"playlists,omitempty"`
	Albums    []TrackInfo `json:"albums,omitempty"`
	Artists   []TrackInfo `json:"artists,omitempty"`
	Error     string      `json:"error,omitempty"`
}

var (
	clientID      = os.Getenv("SPOTIFY_CLIENT_ID")
	clientSecret  = os.Getenv("SPOTIFY_CLIENT_SECRET")
	youtubeAPIKey = os.Getenv("YOUTUBE_API_KEY")
	cachedToken   string
	tokenExpiry   time.Time
	tokenMutex    sync.Mutex
	log           = logrus.New()

	stats DownloadStats
	mu    sync.Mutex // Mutex para proteger stats
)

func init() {
	log.Out = os.Stdout
	log.SetFormatter(&logrus.JSONFormatter{})
}

// getAccessToken retorna um token válido para o serviço especificado ("spotify" ou "youtube").
// Para o Spotify, faz a requisição de Client Credentials e cacheia o token até expirar.
// Para o YouTube, retorna apenas a API key configurada em código.
func getAccessToken(service string) (string, error) {
	tokenMutex.Lock()
	defer tokenMutex.Unlock()

	switch service {
	case "spotify":
		// Se já temos um token Spotify não-expirado, retorna-o
		if cachedToken != "" && time.Now().Before(tokenExpiry) {
			return cachedToken, nil
		}
		// Monta credenciais em base64
		credentials := fmt.Sprintf("%s:%s", clientID, clientSecret)
		encodedCredentials := base64.StdEncoding.EncodeToString([]byte(credentials))

		// Prepara requisição POST para obter token
		reqBody := strings.NewReader("grant_type=client_credentials")
		req, err := http.NewRequest("POST", "https://accounts.spotify.com/api/token", reqBody)
		if err != nil {
			log.WithError(err).Error("Failed to create Spotify token request")
			return "", fmt.Errorf("failed to create Spotify token request: %w", err)
		}
		req.Header.Set("Authorization", "Basic "+encodedCredentials)
		req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			log.WithError(err).Error("Failed to get token from Spotify")
			return "", fmt.Errorf("failed to get token from Spotify: %w", err)
		}
		defer resp.Body.Close()

		var tokenResponse SpotifyToken
		if err := json.NewDecoder(resp.Body).Decode(&tokenResponse); err != nil {
			log.WithError(err).Error("Failed to decode Spotify token response")
			return "", fmt.Errorf("failed to decode Spotify token response: %w", err)
		}

		cachedToken = tokenResponse.AccessToken
		tokenExpiry = time.Now().Add(time.Duration(tokenResponse.ExpiresIn) * time.Second)
		return cachedToken, nil

	case "youtube":
		if youtubeAPIKey == "" {
			return "", fmt.Errorf("YouTube API key not set")
		}
		return youtubeAPIKey, nil

	default:
		return "", fmt.Errorf("unsupported service: %s", service)
	}
}

// contains verifica se uma slice de strings contém um determinado elemento.
func contains(slice []string, str string) bool {
	for _, v := range slice {
		if v == str {
			return true
		}
	}
	return false
}

// extractSpotifyID extrai o ID de uma URL do Spotify
// extractSpotifyID extrai o ID de uma URL do Spotify
func extractSpotifyID(urlStr string) (string, string, error) {
	// Exemplos:
	// https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh
	// https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M
	// https://open.spotify.com/artist/4Z8W4fKeB5YxbusRsdQVPb
	// https://open.spotify.com/album/3eGXGSSlcUc8EU1ABMxtYZ

	parts := strings.Split(urlStr, "/")
	if len(parts) < 2 {
		return "", "", fmt.Errorf("invalid Spotify URL")
	}

	var itemType, itemID string
	for i, part := range parts {
		if part == "track" || part == "playlist" || part == "artist" || part == "album" {
			itemType = part
			if i+1 < len(parts) {
				itemID = strings.Split(parts[i+1], "?")[0] // Remove query parameters
			}
			break
		}
	}

	if itemType == "" || itemID == "" {
		return "", "", fmt.Errorf("could not extract Spotify ID and type")
	}

	return itemType, itemID, nil
}

// getSpotifyItemInfo obtém informações de um item do Spotify
func getSpotifyItemInfo(itemType, itemID string) (*TrackInfo, error) {
	token, err := getAccessToken("spotify")
	if err != nil {
		return nil, err
	}

	var endpoint string
	switch itemType {
	case "track":
		endpoint = fmt.Sprintf("https://api.spotify.com/v1/tracks/%s", itemID)
	case "playlist":
		endpoint = fmt.Sprintf("https://api.spotify.com/v1/playlists/%s", itemID)
	case "artist":
		endpoint = fmt.Sprintf("https://api.spotify.com/v1/artists/%s", itemID)
	case "album":
		endpoint = fmt.Sprintf("https://api.spotify.com/v1/albums/%s", itemID)
	default:
		return nil, fmt.Errorf("unsupported Spotify item type: %s", itemType)
	}

	req, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	trackInfo := &TrackInfo{
		URL:      fmt.Sprintf("https://open.spotify.com/%s/%s", itemType, itemID),
		Platform: "spotify",
		Type:     itemType,
	}

	// Extrai informações específicas por tipo
	switch itemType {
	case "track":
		if name, ok := result["name"].(string); ok {
			trackInfo.Title = name
		}
		if durationMs, ok := result["duration_ms"].(float64); ok {
			minutes := int(durationMs) / 60000
			seconds := (int(durationMs) % 60000) / 1000
			trackInfo.Duration = fmt.Sprintf("%d:%02d", minutes, seconds)
		}
		if album, ok := result["album"].(map[string]interface{}); ok {
			if images, ok := album["images"].([]interface{}); ok && len(images) > 0 {
				if img, ok := images[0].(map[string]interface{}); ok {
					if imgURL, ok := img["url"].(string); ok {
						trackInfo.Thumbnail = imgURL
					}
				}
			}
		}

	case "playlist":
		if name, ok := result["name"].(string); ok {
			trackInfo.Title = name
		}
		if tracks, ok := result["tracks"].(map[string]interface{}); ok {
			if total, ok := tracks["total"].(float64); ok {
				count := int(total)
				trackInfo.TrackCount = &count
			}
		}
		if images, ok := result["images"].([]interface{}); ok && len(images) > 0 {
			if img, ok := images[0].(map[string]interface{}); ok {
				if imgURL, ok := img["url"].(string); ok {
					trackInfo.Thumbnail = imgURL
				}
			}
		}

	case "artist":
		if name, ok := result["name"].(string); ok {
			trackInfo.Title = name
		}
		if images, ok := result["images"].([]interface{}); ok && len(images) > 0 {
			if img, ok := images[0].(map[string]interface{}); ok {
				if imgURL, ok := img["url"].(string); ok {
					trackInfo.Thumbnail = imgURL
				}
			}
		}

	case "album":
		if name, ok := result["name"].(string); ok {
			trackInfo.Title = name
		}
		if images, ok := result["images"].([]interface{}); ok && len(images) > 0 {
			if img, ok := images[0].(map[string]interface{}); ok {
				if imgURL, ok := img["url"].(string); ok {
					trackInfo.Thumbnail = imgURL
				}
			}
		}
		if tracks, ok := result["tracks"].(map[string]interface{}); ok {
			if total, ok := tracks["total"].(float64); ok {
				count := int(total)
				trackInfo.TrackCount = &count
			}
		}
	}

	return trackInfo, nil
}

// getYouTubeVideoInfo obtém informações de um vídeo do YouTube
func getYouTubeVideoInfo(videoID string) (*TrackInfo, error) {
	endpoint := fmt.Sprintf(
		"https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=%s&key=AIzaSyC7pR4w_PkcpfiCsZ_PnGMLynwf0NwCl7g",
		videoID,
	)

	resp, err := http.Get(endpoint)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	items, ok := result["items"].([]interface{})
	if !ok || len(items) == 0 {
		return nil, fmt.Errorf("video not found")
	}

	item := items[0].(map[string]interface{})
	snippet := item["snippet"].(map[string]interface{})

	trackInfo := &TrackInfo{
		URL:      fmt.Sprintf("https://www.youtube.com/watch?v=%s", videoID),
		Platform: "youtube",
		Type:     "track",
	}

	if title, ok := snippet["title"].(string); ok {
		trackInfo.Title = title
	}

	if thumbnails, ok := snippet["thumbnails"].(map[string]interface{}); ok {
		if medium, ok := thumbnails["medium"].(map[string]interface{}); ok {
			if thumbURL, ok := medium["url"].(string); ok {
				trackInfo.Thumbnail = thumbURL
			}
		}
	}

	// Extrai duração se disponível
	if contentDetails, ok := item["contentDetails"].(map[string]interface{}); ok {
		if duration, ok := contentDetails["duration"].(string); ok {
			// Converte duração ISO 8601 (PT4M13S) para formato legível
			trackInfo.Duration = parseYouTubeDuration(duration)
		}
	}

	return trackInfo, nil
}

// getYouTubePlaylistInfo obtém informações de uma playlist do YouTube
func getYouTubePlaylistInfo(playlistID string) (*TrackInfo, error) {
	apiKey, err := getAccessToken("youtube")
	if err != nil {
		return nil, err
	}

	endpoint := fmt.Sprintf(
		"https://www.googleapis.com/youtube/v3/playlists?part=snippet,contentDetails&id=%s&key=%s",
		playlistID, apiKey,
	)

	resp, err := http.Get(endpoint)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	items, ok := result["items"].([]interface{})
	if !ok || len(items) == 0 {
		return nil, fmt.Errorf("playlist not found")
	}

	item := items[0].(map[string]interface{})
	snippet := item["snippet"].(map[string]interface{})

	trackInfo := &TrackInfo{
		URL:      fmt.Sprintf("https://www.youtube.com/playlist?list=%s", playlistID),
		Platform: "youtube",
		Type:     "playlist",
	}

	if title, ok := snippet["title"].(string); ok {
		trackInfo.Title = title
	}

	if thumbnails, ok := snippet["thumbnails"].(map[string]interface{}); ok {
		if medium, ok := thumbnails["medium"].(map[string]interface{}); ok {
			if thumbURL, ok := medium["url"].(string); ok {
				trackInfo.Thumbnail = thumbURL
			}
		}
	}

	// Extrai contagem de vídeos
	if contentDetails, ok := item["contentDetails"].(map[string]interface{}); ok {
		if itemCount, ok := contentDetails["itemCount"].(float64); ok {
			count := int(itemCount)
			trackInfo.TrackCount = &count
		}
	}

	return trackInfo, nil
}

// parseYouTubeDuration converte duração ISO 8601 para formato MM:SS
func parseYouTubeDuration(duration string) string {
	// Exemplo: PT4M13S -> 4:13
	duration = strings.TrimPrefix(duration, "PT")

	var minutes, seconds int

	if strings.Contains(duration, "M") {
		parts := strings.Split(duration, "M")
		if len(parts) > 0 {
			if m, err := strconv.Atoi(parts[0]); err == nil {
				minutes = m
			}
		}
		if len(parts) > 1 {
			secondsPart := strings.TrimSuffix(parts[1], "S")
			if s, err := strconv.Atoi(secondsPart); err == nil {
				seconds = s
			}
		}
	} else if strings.Contains(duration, "S") {
		secondsPart := strings.TrimSuffix(duration, "S")
		if s, err := strconv.Atoi(secondsPart); err == nil {
			seconds = s
		}
	}

	return fmt.Sprintf("%d:%02d", minutes, seconds)
}

// extractYouTubeID extrai o ID de uma URL do YouTube
func extractYouTubeID(urlStr string) (string, string, error) {
	// Exemplos:
	// https://www.youtube.com/watch?v=dQw4w9WgXcQ
	// https://youtu.be/dQw4w9WgXcQ
	// https://www.youtube.com/playlist?list=PLrAXtmRdnEQy6nuLMt9xrTwCu1MxQX2x-

	if strings.Contains(urlStr, "playlist") {
		// É uma playlist
		u, err := url.Parse(urlStr)
		if err != nil {
			return "", "", err
		}
		playlistID := u.Query().Get("list")
		if playlistID == "" {
			return "", "", fmt.Errorf("could not extract playlist ID")
		}
		return "playlist", playlistID, nil
	} else {
		// É um vídeo
		var videoID string
		if strings.Contains(urlStr, "youtu.be/") {
			parts := strings.Split(urlStr, "youtu.be/")
			if len(parts) > 1 {
				videoID = strings.Split(parts[1], "?")[0]
			}
		} else if strings.Contains(urlStr, "watch?v=") {
			u, err := url.Parse(urlStr)
			if err != nil {
				return "", "", err
			}
			videoID = u.Query().Get("v")
		}

		if videoID == "" {
			return "", "", fmt.Errorf("could not extract video ID")
		}
		return "video", videoID, nil
	}
}

// processUrls processa uma lista de URLs e retorna informações sobre cada uma
func processUrls(c *gin.Context) {
	// 1) Bind do JSON de entrada
	var request ProcessUrlsRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}
	if len(request.URLs) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No URLs provided"})
		return
	}

	// 2) Cria 4 fatias distintas e o mutex
	var (
		tracksMu    sync.Mutex
		playlistsMu sync.Mutex
		albumsMu    sync.Mutex
		artistsMu   sync.Mutex

		tracksList    []TrackInfo
		playlistsList []TrackInfo
		albumsList    []TrackInfo
		artistsList   []TrackInfo
	)

	var wg sync.WaitGroup

	for _, urlStr := range request.URLs {
		wg.Add(1)
		go func(urlItem string) {
			defer wg.Done()

			var trackInfo *TrackInfo
			var err error

			// 3) Decide se é Spotify ou YouTube
			if strings.Contains(urlItem, "spotify.com") {
				// Spotify: extrai tipo e ID
				itemType, itemID, extractErr := extractSpotifyID(urlItem)
				if extractErr != nil {
					log.WithError(extractErr).Errorf("Failed to extract Spotify ID from URL: %s", urlItem)
					return
				}
				trackInfo, err = getSpotifyItemInfo(itemType, itemID)
				if err != nil {
					log.WithError(err).Errorf("Failed to get Spotify info for URL: %s", urlItem)
					return
				}

			} else if strings.Contains(urlItem, "youtube.com") || strings.Contains(urlItem, "youtu.be") {
				// YouTube: extrai tipo e ID
				itemType, itemID, extractErr := extractYouTubeID(urlItem)
				if extractErr != nil {
					log.WithError(extractErr).Errorf("Failed to extract YouTube ID from URL: %s", urlItem)
					return
				}
				if itemType == "playlist" {
					trackInfo, err = getYouTubePlaylistInfo(itemID)
				} else {
					trackInfo, err = getYouTubeVideoInfo(itemID)
				}
				if err != nil {
					log.WithError(err).Errorf("Failed to get YouTube info for URL: %s", urlItem)
					return
				}

			} else {
				// Caso não seja YouTube nem Spotify, ignora
				log.Errorf("Unsupported URL: %s", urlItem)
				return
			}

			// 4) A partir de trackInfo.Type, coloca no slice correto
			if trackInfo != nil {
				switch trackInfo.Type {
				case "track":
					tracksMu.Lock()
					tracksList = append(tracksList, *trackInfo)
					tracksMu.Unlock()

				case "playlist":
					playlistsMu.Lock()
					playlistsList = append(playlistsList, *trackInfo)
					playlistsMu.Unlock()

				case "album":
					albumsMu.Lock()
					albumsList = append(albumsList, *trackInfo)
					albumsMu.Unlock()

				case "artist":
					artistsMu.Lock()
					artistsList = append(artistsList, *trackInfo)
					artistsMu.Unlock()

				default:
					// Se vier outro tipo inesperado, trate como track genérico
					tracksMu.Lock()
					tracksList = append(tracksList, *trackInfo)
					tracksMu.Unlock()
				}
			}
		}(urlStr)
	}

	wg.Wait()

	// 5) Monta resposta com as 4 listas
	response := ProcessUrlsResponse{
		Tracks:    tracksList,
		Playlists: playlistsList,
		Albums:    albumsList,
		Artists:   artistsList,
	}

	c.JSON(http.StatusOK, response)
}

// search realiza uma busca unificada em YouTube (vídeos e/ou playlists) e Spotify
// (tracks, artists e/ou playlists), usando todos os parâmetros recebidos via query string.
func search(c *gin.Context) {
	// Parâmetro obrigatório
	query := c.Query("query")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing query"})
		return
	}

	// ==== PARÂMETROS GERAIS ====
	// Para Spotify:
	spotifyTypeParam := c.DefaultQuery("type", "track,artist,playlist,album")
	spotifyLimitParam := c.DefaultQuery("limit", "10")
	spotifyOffsetParam := c.DefaultQuery("offset", "0")

	// Para YouTube:
	youtubeTypeParam := c.DefaultQuery("youtube_type", "video,playlist")
	youtubeMaxResultsParam := c.DefaultQuery("maxResults", "10")

	// Converte limite e offset do Spotify
	limitSpotify, err := strconv.Atoi(spotifyLimitParam)
	if err != nil || limitSpotify < 1 {
		limitSpotify = 10
	}
	offsetSpotify, err := strconv.Atoi(spotifyOffsetParam)
	if err != nil || offsetSpotify < 0 {
		offsetSpotify = 0
	}

	// Converte maxResults do YouTube
	maxResYouTube, err := strconv.Atoi(youtubeMaxResultsParam)
	if err != nil || maxResYouTube < 1 {
		maxResYouTube = 10
	}

	// Slices de tipos para cada serviço
	spotifyTypes := strings.Split(spotifyTypeParam, ",")
	youtubeTypes := strings.Split(youtubeTypeParam, ",")

	// Mapas para guardar resultados
	youtubeResult := make(map[string]interface{})
	spotifyResult := make(map[string]interface{})

	var wg sync.WaitGroup

	// ==== BUSCA NO YOUTUBE ====
	wg.Add(1)
	go func() {
		defer wg.Done()

		apiKey, err := getAccessToken("youtube")

		log.Printf("YouTube API Key: %s", apiKey)

		if err != nil {
			log.WithError(err).Error("Failed to get YouTube API key")
			return
		}

		escapedQuery := url.QueryEscape(query)

		// Para cada tipo indicado (ex: "video" ou "playlist")
		for _, mediaType := range youtubeTypes {
			mediaType = strings.TrimSpace(mediaType)
			if mediaType == "" {
				continue
			}

			// Monta URL de busca:
			// https://www.googleapis.com/youtube/v3/search?part=snippet&q=<query>&type=<mediaType>&maxResults=<n>&key=<apiKey>
			endpoint := fmt.Sprintf(
				"https://www.googleapis.com/youtube/v3/search?part=snippet&q=%s&type=%s&maxResults=%d&key=%s",
				escapedQuery, mediaType, maxResYouTube, apiKey,
			)

			resp, err := http.Get(endpoint)
			if err != nil {
				log.WithError(err).Errorf("Failed to search YouTube %s", mediaType)
				continue
			}
			defer resp.Body.Close()

			var result map[string]interface{}
			if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
				log.WithError(err).Errorf("Failed to decode YouTube %s response", mediaType)
				continue
			}

			// Extrai o array "items" e armazena em youtubeResult["videos"] ou ["playlists"]
			if itemsRaw, ok := result["items"].([]interface{}); ok {
				key := mediaType + "s" // ex: "videos" ou "playlists"
				youtubeResult[key] = itemsRaw
			}
		}
	}()

	// ==== BUSCA NO SPOTIFY ====
	wg.Add(1)
	go func() {
		defer wg.Done()

		token, err := getAccessToken("spotify")
		if err != nil {
			log.WithError(err).Error("Failed to get Spotify token")
			return
		}

		escapedQuery := url.QueryEscape(query)

		// Variáveis para paginação e totais
		var totalTracks, totalArtists, totalPlaylists, totalAlbums int
		var hasNextTrack, hasPrevTrack bool
		var hasNextArtist, hasPrevArtist bool
		var hasNextPlaylist, hasPrevPlaylist bool
		var hasNextAlbum, hasPrevAlbum bool

		for _, endpointType := range spotifyTypes {
			endpointType = strings.TrimSpace(endpointType)
			if endpointType == "" {
				continue
			}

			// Monta URL de busca:
			// https://api.spotify.com/v1/search?q=<query>&type=<endpointType>&limit=<limit>&offset=<offset>
			urlSearch := fmt.Sprintf(
				"https://api.spotify.com/v1/search?q=%s&type=%s&limit=%d&offset=%d",
				escapedQuery, endpointType, limitSpotify, offsetSpotify,
			)

			req, _ := http.NewRequest("GET", urlSearch, nil)
			req.Header.Set("Authorization", "Bearer "+token)

			client := &http.Client{}
			resp, err := client.Do(req)
			if err != nil {
				log.WithError(err).Errorf("Failed to search Spotify %s", endpointType)
				continue
			}

			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()

			var result map[string]interface{}
			if err := json.Unmarshal(body, &result); err != nil {
				log.WithError(err).Errorf("Failed to decode Spotify %s response", endpointType)
				continue
			}

			keyPlural := endpointType + "s" // "tracks", "artists", "playlists" ou "albums"
			endpointData, ok := result[keyPlural].(map[string]interface{})
			if !ok {
				continue
			}

			// Extrai "items"
			itemsRaw, ok := endpointData["items"].([]interface{})
			if !ok {
				continue
			}

			// Sanitização: remove "available_markets" de cada item, se existir
			sanitizeItem := func(item map[string]interface{}, keysToRemove []string) map[string]interface{} {
				for _, key := range keysToRemove {
					delete(item, key)
				}
				return item
			}
			keysToRemove := []string{"available_markets"}

			formattedItems := make([]interface{}, 0, len(itemsRaw))
			for _, raw := range itemsRaw {
				if itemMap, ok := raw.(map[string]interface{}); ok {
					formattedItems = append(formattedItems, sanitizeItem(itemMap, keysToRemove))
				}
			}

			spotifyResult[keyPlural] = formattedItems

			// Extrai metadados de paginação / total
			if totalVal, ok := endpointData["total"].(float64); ok {
				switch endpointType {
				case "track":
					totalTracks = int(totalVal)
				case "artist":
					totalArtists = int(totalVal)
				case "playlist":
					totalPlaylists = int(totalVal)
				case "album":
					totalAlbums = int(totalVal)
				}
			}
			if nextURL, ok := endpointData["next"].(string); ok {
				hasNext := nextURL != ""
				switch endpointType {
				case "track":
					hasNextTrack = hasNext
				case "artist":
					hasNextArtist = hasNext
				case "playlist":
					hasNextPlaylist = hasNext
				case "album":
					hasNextAlbum = hasNext
				}
			}
			if prevURL, ok := endpointData["previous"].(string); ok {
				hasPrev := prevURL != ""
				switch endpointType {
				case "track":
					hasPrevTrack = hasPrev
				case "artist":
					hasPrevArtist = hasPrev
				case "playlist":
					hasPrevPlaylist = hasPrev
				case "album":
					hasPrevAlbum = hasPrev
				}
			}
		}

		// Monta objeto de paginação para Spotify
		pagination := gin.H{
			"limit":  limitSpotify,
			"offset": offsetSpotify,

			"total_tracks":       totalTracks,
			"has_next_track":     hasNextTrack,
			"has_previous_track": hasPrevTrack,

			"total_artists":       totalArtists,
			"has_next_artist":     hasNextArtist,
			"has_previous_artist": hasPrevArtist,

			"total_playlists":       totalPlaylists,
			"has_next_playlist":     hasNextPlaylist,
			"has_previous_playlist": hasPrevPlaylist,

			"total_albums":       totalAlbums,
			"has_next_album":     hasNextAlbum,
			"has_previous_album": hasPrevAlbum,
		}
		spotifyResult["pagination"] = pagination
	}()

	// Aguarda ambas as buscas terminarem
	wg.Wait()

	c.JSON(http.StatusOK, gin.H{
		"youtube": youtubeResult,
		"spotify": spotifyResult,
	})
}

// downloadMusic recebe um JSON com URLs de vídeos/links do Spotify e inicia múltiplos downloads
// em paralelo (um worker por URL). A saída de cada comando é streamada de volta ao cliente.
func downloadMusic(c *gin.Context) {
	var request struct {
		URLs []string `json:"urls"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if len(request.URLs) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No URLs provided"})
		return
	}

	// Headers para streaming de resposta
	c.Writer.Header().Set("Content-Type", "text/plain")
	c.Writer.Header().Set("Transfer-Encoding", "chunked")
	c.Writer.WriteHeader(http.StatusOK)

	var wg sync.WaitGroup
	var mu sync.Mutex

	workerCount := 0

	for _, downloadURL := range request.URLs {
		wg.Add(1)
		workerCount++

		go func(urlStr string) {
			defer wg.Done()

			var cmd *exec.Cmd
			if strings.Contains(urlStr, "spotify") {
				cmd = exec.Command("docker", "exec", "-i", "spotDL", "spotdl", urlStr)
			} else {
				cmd = exec.Command(
					"docker", "exec", "-i", "yt-dlp",
					"yt-dlp", "-f", "bestaudio", "--extract-audio",
					"--audio-format", "mp3", "--progress",
					"-o", "/downloads/%(title)s.%(ext)s", urlStr,
				)
			}

			stdout, err := cmd.StdoutPipe()
			if err != nil {
				log.WithError(err).Error("Failed to create stdout pipe")
				mu.Lock()
				c.Writer.Write([]byte(fmt.Sprintf("Failed to start download for URL %s\n", urlStr)))
				c.Writer.Flush()
				mu.Unlock()
				return
			}

			stderr, err := cmd.StderrPipe()
			if err != nil {
				log.WithError(err).Error("Failed to create stderr pipe")
				mu.Lock()
				c.Writer.Write([]byte(fmt.Sprintf("Failed to start download for URL %s\n", urlStr)))
				c.Writer.Flush()
				mu.Unlock()
				return
			}

			if err := cmd.Start(); err != nil {
				log.WithError(err).Error("Failed to start download command")
				mu.Lock()
				c.Writer.Write([]byte(fmt.Sprintf("Failed to start download for URL %s\n", urlStr)))
				c.Writer.Flush()
				mu.Unlock()
				return
			}

			scanner := bufio.NewScanner(io.MultiReader(stdout, stderr))
			for scanner.Scan() {
				chunk := fmt.Sprintf("[%s] %s\n", urlStr, scanner.Text())
				mu.Lock()
				if _, err := c.Writer.Write([]byte(chunk)); err != nil {
					log.WithError(err).Error("Failed to write chunk to client")
					mu.Unlock()
					return
				}
				c.Writer.Flush()
				mu.Unlock()
			}

			if err := cmd.Wait(); err != nil {
				log.WithError(err).Error("Download command failed")
				mu.Lock()
				c.Writer.Write([]byte(fmt.Sprintf("Download failed for URL %s: %s\n", urlStr, err.Error())))
				c.Writer.Flush()
				mu.Unlock()
				return
			}

			mu.Lock()
			c.Writer.Write([]byte(fmt.Sprintf("Download completed successfully for URL %s\n", urlStr)))
			c.Writer.Flush()
			mu.Unlock()
		}(downloadURL)
	}

	// Informa quantos workers foram iniciados
	mu.Lock()
	c.Writer.Write([]byte(fmt.Sprintf("Number of workers: %d\n", workerCount)))
	c.Writer.Flush()
	mu.Unlock()

	wg.Wait()

	// Finaliza streaming da resposta
	mu.Lock()
	c.Writer.Write([]byte("All downloads completed\n"))
	c.Writer.Flush()
	mu.Unlock()
}

func main() {
	r := gin.Default()

	// Rota principal de busca (YouTube + Spotify, incluindo parâmetros de query)
	r.GET("/search", search)

	// Rota de processamento de URLs
	r.POST("/process-urls", processUrls)

	// Rota de download
	r.POST("/download", downloadMusic)

	port := os.Getenv("PORT")
	if port == "" {
		port = "3333"
	}

	log.Infof("Server started on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.WithError(err).Fatal("Failed to start server")
	}
}
