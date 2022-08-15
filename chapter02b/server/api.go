package server

import (
	"net/http"

	"github.com/NucleusEngineering/dogcat/chapter02b/ent/db"

	"github.com/gin-gonic/gin"
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

var foodMap = map[string]Controller{
	"sausage": ControllerDog,
	"fish":    ControllerCat,
}

func AddAPIRoutes(e *db.Client, r gin.IRoutes) {
	r.POST("/api/foods", func(c *gin.Context) {
		data := struct { // TODO: move out
			Length      float64 `json:"length"`
			UpdateCount float64 `json:"updateCount"`
		}{}
		if err := c.BindJSON(&data); err != nil {
			c.JSON(http.StatusBadRequest, map[string]string{"message": "Required arguments not provided!"})
			return
		}

		// factor := math.Max(math.Min((data.Length/30.0+data.UpdateCount/200.0)/2.0, 1.0), 0.0)
		// foodAmount := math.Round(minFood + (maxFood-minFood)*factor)
		// tickRate := math.Round(minTickRate + (maxTickRate-minTickRate)*factor)

	})
}
