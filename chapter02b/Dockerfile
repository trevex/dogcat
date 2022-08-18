FROM docker.io/golang:1.18-alpine AS build

RUN apk add --no-cache git nodejs yarn
WORKDIR /src

# Let's install all node-modules
RUN mkdir web
COPY ./web/package.json ./web/yarn.lock ./web/
RUN yarn --cwd ./web install

# Let's preload all go-modules
COPY ./go.mod ./go.sum ./
RUN go mod download

COPY ./ ./

# Generate static assets
RUN yarn --cwd ./web run export

# Build the executable
RUN CGO_ENABLED=0 go build \
    -installsuffix 'static' \
    -o /dogcat ./cmd/dogcat/main.go


FROM gcr.io/distroless/static
USER nonroot:nonroot
COPY --from=build --chown=nonroot:nonroot /dogcat /dogcat

ENTRYPOINT ["/dogcat"]
