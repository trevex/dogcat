package server

import (
	"math"
	"math/rand"
	"net/http"
	"time"

	"github.com/NucleusEngineering/dogcat/chapter02b/ent/db"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
	"golang.org/x/exp/slices"
)

const (
	minFood     = 2.0
	maxFood     = 8.0
	minTickRate = 200.0
	maxTickRate = 30.0
)

type Controller int64

const (
	ControllerCat Controller = 1
	ControllerDog            = 2
)

type Score struct {
	Username  string    `json:"username"`
	Score     int       `json:"score"`
	CreatedAt time.Time `json:"createdAt"`
	Recent    bool      `json:"recent"`
}

var foodMap = map[string]Controller{
	"sausage": ControllerDog,
	"fish":    ControllerCat,
}

var foodKeys = func() []string {
	keys := make([]string, 0, len(foodMap))
	for k := range foodMap {
		keys = append(keys, k)
	}
	return keys
}()

func AddAPIRoutes(e *db.Client, r gin.IRoutes) {
	r.POST("/api/foods", func(c *gin.Context) {
		data := struct {
			Length      float64 `json:"length"`
			UpdateCount float64 `json:"updateCount"`
		}{}
		if err := c.BindJSON(&data); err != nil {
			c.JSON(http.StatusBadRequest, map[string]string{"message": "Required arguments not provided!"})
			return
		}

		factor := math.Max(math.Min((data.Length/30.0+data.UpdateCount/200.0)/2.0, 1.0), 0.0)
		foodAmount := int(math.Round(minFood + (maxFood-minFood)*factor))
		tickRate := math.Round(minTickRate + (maxTickRate-minTickRate)*factor)

		// We mimic the original Typescript code here and are returning a tuple
		foods := make([][]any, 0, foodAmount)
		for i := foodAmount; i > 0; i-- {
			foodName := foodKeys[rand.Intn(len(foodKeys))]
			foods = append(foods, []any{
				struct {
					X int `json:"x"`
					Y int `json:"y"`
				}{0, 0},
				foodName,
				foodMap[foodName],
			})
		}

		result := struct {
			Foods    [][]any `json:"foods"`
			TickRate float64 `json:"tickRate"`
		}{foods, tickRate}

		c.JSON(http.StatusOK, &result)
	})

	handleGetScores := func(recentScore *db.Score) gin.HandlerFunc {
		return func(c *gin.Context) {
			scores, err := e.Score.Query().Limit(10).Order(db.Desc("score")).All(c.Request.Context())
			if err != nil {
				log.Error().Err(err).Msg("failed listing scores")
				c.JSON(http.StatusInternalServerError, map[string]string{"message": "Failed listing scores!"})
				return
			}

			// Let's see if recentScore was set, and if so, we check if we still need to
			// add it to our return values
			if recentScore != nil {
				if idx := slices.IndexFunc(scores, func(s *db.Score) bool { return s.ID == recentScore.ID }); idx < 0 {
					// Score not listed yet
					scores = scores[:len(scores)-1] // So let's remove last element and insert ours
					scores = append(scores, recentScore)
				}
			}

			// Let's compute our output
			result := make([]Score, 0, len(scores))
			for _, s := range scores {
				result = append(result, Score{
					Username:  s.Username,
					Score:     s.Score,
					CreatedAt: s.CreatedAt,
					Recent:    recentScore != nil && s.ID == recentScore.ID,
				})
			}
			c.JSON(http.StatusOK, &result)
		}
	}

	r.POST("/api/scores", func(c *gin.Context) {
		data := struct {
			Score    int    `json:"score"`
			Username string `json:"username"`
		}{}
		if err := c.BindJSON(&data); err != nil {
			c.JSON(http.StatusBadRequest, map[string]string{"message": "Required arguments not provided!"})
			return
		}

		recentScore, err := e.Score.Create().
			SetScore(data.Score).
			SetUsername(data.Username).Save(c.Request.Context())
		if err != nil {
			log.Error().Err(err).Msg("failed saving score")
			c.JSON(http.StatusInternalServerError, map[string]string{"message": "Failed saving score!"})
			return
		}

		handleGetScores(recentScore)(c)
	})
	r.GET("/api/scores", handleGetScores(nil))
}
